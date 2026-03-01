// skills/mintclub/scripts/mintclub-client.ts
// MintClub Stakers client — ERC-8128 auth + x402 micropaiement
// Fetches onchain stakers for any MintClub staking pool on Base
// Exécuté par Node 24+ (TypeScript stripping natif)

import { createSignerClient } from "@slicekit/erc8128";
import type { EthHttpSigner } from "@slicekit/erc8128";
import { x402Client, wrapFetchWithPayment } from "@x402/fetch";
import { registerExactEvmScheme } from "@x402/evm/exact/client";
import { privateKeyToAccount } from "viem/accounts";

const MCP_BASE_URL = "https://node.specuverse.xyz";
const PRIVATE_KEY = (process.env.WALLET_PRIVATE_KEY || process.env.PRIVATE_KEY || process.env.CLANKER_PRIVATE_KEY) as `0x${string}`;

if (!PRIVATE_KEY) {
  console.log(JSON.stringify({ success: false, error: "WALLET_PRIVATE_KEY (or PRIVATE_KEY) missing" }));
  process.exit(1);
}

// --- Wallet ---
const account = privateKeyToAccount(PRIVATE_KEY);

// --- ERC-8128 signer (auth HTTP) ---
const erc8128Signer: EthHttpSigner = {
  chainId: 8453,
  address: account.address,
  signMessage: async (message: Uint8Array) =>
    account.signMessage({ message: { raw: message } }),
};
const signerClient = createSignerClient(erc8128Signer);

// --- x402 client (micropaiement USDC) ---
const paymentClient = new x402Client();
registerExactEvmScheme(paymentClient, { signer: account });
const fetchWithPayment = wrapFetchWithPayment(fetch, paymentClient);

// --- Helpers ---
function parsePaymentRequiredHeader(response: Response): unknown {
  const paymentHeader = response.headers.get("payment-required");
  if (!paymentHeader) return null;
  try {
    return JSON.parse(Buffer.from(paymentHeader, "base64").toString("utf-8"));
  } catch {
    return paymentHeader;
  }
}

// --- Main ---
const args = process.argv.slice(2);
const poolId = args[0];

if (!poolId || !/^\d+$/.test(poolId)) {
  console.log(JSON.stringify({
    success: false,
    error: "Usage: mintclub-client.ts <poolId> [limit=N] [offset=N] [includePool=true|false] [fields=...] [version=v1|v2]",
  }));
  process.exit(1);
}

// Parse key=value params
const queryParams: Record<string, string> = {};
for (const a of args.slice(1)) {
  if (a.includes("=")) {
    const [k, ...vParts] = a.split("=");
    queryParams[k] = vParts.join("=");
  }
}

// Build URL
const path = `/mcp/mintclub/pool/${poolId}/stakers`;
const qs = Object.keys(queryParams).length > 0
  ? "?" + new URLSearchParams(queryParams).toString()
  : "";
const url = `${MCP_BASE_URL}${path}${qs}`;

async function run(): Promise<void> {
  // Mode quote (pas de paiement) — par défaut
  if (process.env.MCP_PAY !== "1") {
    const signedReq = await signerClient.signRequest(url, { method: "GET" });
    const quoteResp = await fetch(signedReq);

    if (quoteResp.status === 402) {
      const invoice = parsePaymentRequiredHeader(quoteResp);
      console.log(JSON.stringify({
        success: false,
        status: 402,
        poolId: Number(poolId),
        paid: true,
        mode: "quote",
        note: "Payment required. Set MCP_PAY=1 to authorize spending.",
        invoice,
      }, null, 2));
      process.exit(0);
    }

    const body = await quoteResp.text();
    let data: unknown;
    try { data = JSON.parse(body); } catch { data = body; }
    console.log(JSON.stringify({
      success: quoteResp.status >= 200 && quoteResp.status < 300,
      status: quoteResp.status,
      poolId: Number(poolId),
      paid: false,
      data,
    }, null, 2));
    return;
  }

  // Mode pay — x402 micropaiement
  const signedReq = await signerClient.signRequest(url, { method: "GET" });
  const response = await fetchWithPayment(signedReq);

  const status = response.status;
  const body = await response.text();
  let data: unknown;
  try { data = JSON.parse(body); } catch { data = body; }

  const result: Record<string, unknown> = {
    success: status >= 200 && status < 300,
    status,
    poolId: Number(poolId),
    paid: true,
    data,
  };

  const paymentResponse = response.headers.get("payment-response");
  if (paymentResponse) {
    result.paymentProof = paymentResponse.substring(0, 200);
  }

  console.log(JSON.stringify(result, null, 2));
}

run().catch((err: Error) => {
  console.log(JSON.stringify({ success: false, error: err.message }));
  process.exit(1);
});
