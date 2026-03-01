#!/bin/bash
# MintClub Pools — list all staking pools on Base (V1 + V2 contracts)
# Usage: mintclub-pools.sh [key=value ...]
#
# Paid: $0.01 USDC per call (x402 micropayment on Base)
#
# Examples:
#   mintclub-pools.sh                          # All pools (V1 + V2)
#   mintclub-pools.sh version=v1               # V1 pools only
#   mintclub-pools.sh version=v2               # V2 pools only
#   mintclub-pools.sh status=active            # Active pools only
#   mintclub-pools.sh version=v1 status=active # V1 active pools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify deps are installed
for pkg in "@slicekit/erc8128" "@x402/fetch" "@x402/evm" "viem"; do
    if [[ ! -d "$SCRIPT_DIR/../node_modules/$pkg" ]]; then
        echo "{\"success\":false,\"error\":\"Package $pkg not found. Run: npm install\"}"
        exit 1
    fi
done

# Env check
if [[ -z "${WALLET_PRIVATE_KEY:-}" && -z "${PRIVATE_KEY:-}" && -z "${CLANKER_PRIVATE_KEY:-}" ]]; then
    echo '{"success":false,"error":"WALLET_PRIVATE_KEY (or PRIVATE_KEY) not set"}'
    exit 1
fi

# Back-compat: allow CLANKER_PRIVATE_KEY (internal name)
if [[ -z "${WALLET_PRIVATE_KEY:-}" && -z "${PRIVATE_KEY:-}" && -n "${CLANKER_PRIVATE_KEY:-}" ]]; then
  export WALLET_PRIVATE_KEY="$CLANKER_PRIVATE_KEY"
fi
if [[ -z "${WALLET_PRIVATE_KEY:-}" && -n "${PRIVATE_KEY:-}" ]]; then
  export WALLET_PRIVATE_KEY="$PRIVATE_KEY"
fi

echo '⚠️  Route payante — 0.01 USDC sera dépensé sur Base' >&2

# Execute TypeScript client via Node 24+ (native TS stripping)
exec node --experimental-strip-types "$SCRIPT_DIR/pools-client.ts" "$@"
