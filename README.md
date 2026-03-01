# mintclub-stakers-mcp — Pay-per-call MintClub staking data on Base

**What:** An API + client scripts to **list all MintClub staking pools (V1+V2)** and **export stakers of any pool**.

**Key differentiator:** every staker can be **enriched with Farcaster identity + social metrics via Neynar** (fid, username, display name, pfp, follower count, Neynar score).

**Why:** snapshots for airdrops targeting, anti-sybil heuristics, governance analysis, whale tracking, rewards distribution.

## Pricing

- **$0.01 USDC per call**
- Onchain micropayment via **x402** on **Base**
- **No subscription, no API key**
- **Quote mode** (no payment) is available to inspect the invoice

## Quickstart

### Prerequisites

- **Node 24+**
- A wallet with **USDC on Base** (and some ETH for gas)
- Set your private key in env (example):

```bash
export WALLET_PRIVATE_KEY=0x...   # your wallet, used to sign (ERC-8128) and pay (x402)
# (alias supported: PRIVATE_KEY)
```

### Install

```bash
npm install
```

### Run (quote mode by default)

```bash
./scripts/mintclub-pools.sh
./scripts/mintclub-stakers.sh 157
```

### Run (paid mode)

```bash
export MCP_PAY=1
./scripts/mintclub-pools.sh
./scripts/mintclub-stakers.sh 157
```

## API Reference

Base URL:

- `https://node.specuverse.xyz`

### 1) List pools

`GET https://node.specuverse.xyz/mcp/mintclub/pools`

Query params:

| Param | Type | Default | Description |
|---|---:|---:|---|
| `version` | string | `all` | `v1`, `v2`, or `all` |
| `status` | string | _(none)_ | `active`, `cancelled`, `finished`, `pending` |
| `fields` | string | `poolId,version,status,stakingToken,rewardToken,totalStaked,activeStakerCount` | Comma-separated projection |

Example:

```bash
./scripts/mintclub-pools.sh version=v2 status=active
```

### 2) Pool stakers

`GET https://node.specuverse.xyz/mcp/mintclub/pool/:poolId/stakers`

Path params:

| Param | Type | Required | Description |
|---|---:|---:|---|
| `poolId` | number | yes | MintClub pool id |

Query params:

| Param | Type | Default | Description |
|---|---:|---:|---|
| `version` | string | `v2` | `v1` or `v2` (if stakers are empty on v2, retry v1) |
| `limit` | number | `100` | 1–500 |
| `offset` | number | `0` | Pagination offset |
| `includePool` | boolean | `true` | Include onchain pool metadata |
| `fields` | string | `address,totalStaked,fid,username,displayName,pfpUrl,followerCount,neynarScore` | Comma-separated staker projection |

Example:

```bash
./scripts/mintclub-stakers.sh 157 limit=50 offset=0 includePool=true
```

## Farcaster enrichment (Neynar)

This backend can enrich onchain addresses with **Farcaster profiles via Neynar** so your staker exports are immediately usable.

Typical enriched fields:
- `fid`, `username`, `displayName`, `pfpUrl`
- `followerCount`
- `neynarScore`

This enrichment is handled **server-side** (you don’t need to bring a Neynar API key).

## Authentication

- **ERC-8128**: the client **signs the HTTP request** with your wallet.
- **No API keys**.

## Payment

- **x402** pay-per-call protocol (Base)
- Default is **quote mode**: if `MCP_PAY` is not `1`, the server returns **402 + invoice**.
- Set `MCP_PAY=1` to authorize spending and pay **0.01 USDC** per call.

## Trust model

- Your wallet signs/pays.
- The backend is **closed-source**.
- No secrets are included in this repo.
- Data is read from onchain event logs + contract views (plus optional Farcaster enrichment).

## Contracts

Two staking contracts exist on Base:

- **V1** (older pools): `0x3460e2fd6cbc9afb49bf970659afde2909cf3399`
- **V2** (newer pools): `0x9ab05eca10d087f23a1b22a44a714cdbba76e802`

## OpenClaw

OpenClaw users can use the adapter file:

- `openclaw/SKILL.md`

(Repo remains usable without OpenClaw.)

## Rate limits

- Paid routes: **10 req/min**

## Examples

See `examples/` for:
- quote-mode outputs (402 invoices)
- paid-mode outputs (successful JSON payloads)

Notes:
- Previously this endpoint was observed returning intermittent `500`s.
- **As of 2026-03-01**, a **paid** call returned **HTTP 200** successfully (`totalPools=241`, `v1Count=36`, `v2Count=205`). See: `examples/pools.paid.20260301T042109Z.json`

## License

MIT
