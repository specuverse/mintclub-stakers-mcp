---
name: mintclub-mcp
description: MintClub staking on Base — list all pools (V1+V2) and query stakers per pool. Paid $0.01 USDC per call via x402.
metadata: {"openclaw": {"emoji": "🏦", "requires": {"env": ["WALLET_PRIVATE_KEY"]}, "primaryEnv": "WALLET_PRIVATE_KEY"}}
---

# mintclub-mcp (OpenClaw adapter)

This repo is generic (standalone scripts + Node). This file is an **optional adapter** for OpenClaw users.

## Install (OpenClaw)

1) Copy this repo somewhere on your machine.
2) Ensure `WALLET_PRIVATE_KEY` is set in your OpenClaw environment.
3) Point OpenClaw at the scripts in this repo.

At minimum, you need:
- `scripts/mintclub-pools.sh`
- `scripts/mintclub-stakers.sh`
- `scripts/pools-client.ts`
- `scripts/stakers-client.ts`

## Notes

- Node 24+ required (uses `--experimental-strip-types`).
- Run `npm install` once at repo root.
- Default is **quote mode** (no payment). Set `MCP_PAY=1` to pay.
