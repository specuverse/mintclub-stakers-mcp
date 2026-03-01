#!/bin/bash
# MintClub Stakers — query onchain stakers for any MintClub staking pool on Base
# Usage: mintclub.sh <poolId> [key=value ...]
#
# Paid: $0.01 USDC per call (x402 micropayment on Base)
#
# Examples:
#   mintclub.sh 157
#   mintclub.sh 157 limit=50 offset=0
#   mintclub.sh 157 includePool=true
#   mintclub.sh 157 fields=address,totalStaked
#   mintclub.sh 36 version=v1        # Old staking contract

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

POOL_ID="${1:-}"

if [[ -z "$POOL_ID" ]]; then
    echo '{"success":false,"error":"Usage: mintclub.sh <poolId> [limit=N] [offset=N] [includePool=true|false] [fields=address,totalStaked]"}'
    exit 1
fi

# Validate poolId is a positive integer
if ! [[ "$POOL_ID" =~ ^[0-9]+$ ]]; then
    echo '{"success":false,"error":"poolId must be a positive integer"}'
    exit 1
fi

echo '⚠️  Route payante — 0.01 USDC sera dépensé sur Base' >&2

# Execute TypeScript client via Node 24+ (native TS stripping)
exec node --experimental-strip-types "$SCRIPT_DIR/stakers-client.ts" "$@"
