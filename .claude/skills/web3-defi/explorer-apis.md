# Block Explorer APIs

Referenced from `SKILL.md`. Read this file when working with Etherscan, BscScan, BaseScan, Solscan, or other block explorer APIs.

Last verified: 2026-03-05

## Etherscan API Structure (EVM Chains)

### Base URL Pattern
```
https://api.etherscan.io/api?module=<MODULE>&action=<ACTION>&apikey=<KEY>
```

### API Modules

| Module | Key Actions | Description |
|--------|-------------|-------------|
| `account` | `balance`, `balancemulti`, `txlist`, `txlistinternal`, `tokentx`, `tokennfttx`, `tokenbalance` | Account balances, transaction history, token transfers |
| `contract` | `getabi`, `getsourcecode`, `verifysourcecode` | Contract ABI, source code, verification |
| `transaction` | `getstatus`, `gettxreceiptstatus` | Transaction execution status |
| `block` | `getblockreward`, `getblockcountdown`, `getblocknobytime` | Block info, countdown, timestamp lookup |
| `logs` | `getLogs` | Event logs (critical for DeFi — swap events, mint/burn events) |
| `gastracker` | `gasestimate`, `gasoracle` | Gas price estimation |
| `stats` | `ethsupply`, `ethprice`, `chainsize` | Network statistics |
| `token` | `tokeninfo`, `tokenholderlist` | ERC-20 token metadata |

### Rate Limits
- **Free tier**: 5 calls/second, 100,000 calls/day
- **Paid tiers**: 10-30 calls/second depending on plan
- All responses include `status`, `message`, `result` fields

### Authentication
```python
# Single API key works across 50+ Etherscan-powered explorers
ETHERSCAN_API_KEY = os.environ["ETHERSCAN_API_KEY"]
```

## Multi-Chain Explorer URLs

All EVM-compatible explorers follow the same API structure:

| Chain | Explorer | API Base URL |
|-------|----------|-------------|
| Ethereum | Etherscan | `https://api.etherscan.io/api` |
| BNB Chain | BscScan | `https://api.bscscan.com/api` |
| Base | BaseScan | `https://api.basescan.org/api` |
| Arbitrum | Arbiscan | `https://api.arbiscan.io/api` |
| Polygon | PolygonScan | `https://api.polygonscan.com/api` |
| Optimism | Optimistic | `https://api-optimistic.etherscan.io/api` |
| Avalanche | Snowtrace | `https://api.snowtrace.io/api` |
| Fantom | FTMScan | `https://api.ftmscan.com/api` |

## Python Client for EVM Explorers

```python
import httpx
import os
from datetime import datetime, timezone


class EVMExplorerClient:
    """Unified async client for Etherscan-compatible block explorer APIs."""

    CHAIN_URLS = {
        "ethereum": "https://api.etherscan.io/api",
        "bnb": "https://api.bscscan.com/api",
        "base": "https://api.basescan.org/api",
        "arbitrum": "https://api.arbiscan.io/api",
        "polygon": "https://api.polygonscan.com/api",
        "optimism": "https://api-optimistic.etherscan.io/api",
    }

    def __init__(self, api_key: str, chain: str = "ethereum"):
        self.api_key = api_key
        self.base_url = self.CHAIN_URLS[chain]
        self.client = httpx.AsyncClient(timeout=30.0)

    async def _request(self, module: str, action: str, **params) -> dict:
        """Make an API request with rate limiting awareness."""
        params.update({
            "module": module,
            "action": action,
            "apikey": self.api_key,
        })
        response = await self.client.get(self.base_url, params=params)
        response.raise_for_status()
        data = response.json()
        if data["status"] != "1" and data["message"] != "No transactions found":
            raise ValueError(f"API error: {data['message']} - {data.get('result', '')}")
        return data["result"]

    async def get_token_transfers(
        self,
        address: str,
        contract_address: str | None = None,
        start_block: int = 0,
        end_block: int = 99999999,
        sort: str = "desc",
    ) -> list[dict]:
        """Get ERC-20 token transfer events for an address."""
        params = {
            "address": address,
            "startblock": start_block,
            "endblock": end_block,
            "sort": sort,
        }
        if contract_address:
            params["contractaddress"] = contract_address
        return await self._request("account", "tokentx", **params)

    async def get_logs(
        self,
        address: str,
        topic0: str,
        from_block: int,
        to_block: int,
    ) -> list[dict]:
        """Get event logs — essential for tracking swaps, mints, burns."""
        return await self._request(
            "logs", "getLogs",
            address=address,
            topic0=topic0,
            fromBlock=from_block,
            toBlock=to_block,
        )

    async def get_contract_abi(self, address: str) -> str:
        """Get verified contract ABI (JSON string)."""
        return await self._request("contract", "getabi", address=address)

    async def get_gas_oracle(self) -> dict:
        """Get current gas prices (low, average, high)."""
        return await self._request("gastracker", "gasoracle")

    async def get_eth_price(self) -> dict:
        """Get current ETH price in USD and BTC."""
        return await self._request("stats", "ethprice")

    async def close(self):
        await self.client.aclose()
```

## Common DeFi Patterns with Explorer APIs

### Fetch Pool Creation Events
```python
# Uniswap v3 PoolCreated event topic
POOL_CREATED_TOPIC = "0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118"

async def find_pools_for_token(
    explorer: EVMExplorerClient,
    factory_address: str,
    token_address: str,
    from_block: int = 0,
) -> list[dict]:
    """Find all pools containing a specific token."""
    logs = await explorer.get_logs(
        address=factory_address,
        topic0=POOL_CREATED_TOPIC,
        from_block=from_block,
        to_block=99999999,
    )
    pools = []
    for log in logs:
        # Decode topics: topic1=token0, topic2=token1, topic3=fee
        token0 = "0x" + log["topics"][1][-40:]
        token1 = "0x" + log["topics"][2][-40:]
        if token_address.lower() in (token0.lower(), token1.lower()):
            pools.append({
                "pool_address": "0x" + log["data"][-40:],
                "token0": token0,
                "token1": token1,
                "block": int(log["blockNumber"], 16),
            })
    return pools
```

### Fetch Swap History
```python
# Uniswap v3 Swap event topic
SWAP_TOPIC = "0xc42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67"

async def get_swap_history(
    explorer: EVMExplorerClient,
    pool_address: str,
    from_block: int,
    to_block: int,
) -> list[dict]:
    """Get swap events for a pool via explorer API."""
    logs = await explorer.get_logs(
        address=pool_address,
        topic0=SWAP_TOPIC,
        from_block=from_block,
        to_block=to_block,
    )
    swaps = []
    for log in logs:
        # Decode data: amount0, amount1, sqrtPriceX96, liquidity, tick
        data = bytes.fromhex(log["data"][2:])
        amount0 = int.from_bytes(data[0:32], "big", signed=True)
        amount1 = int.from_bytes(data[32:64], "big", signed=True)
        sqrt_price = int.from_bytes(data[64:96], "big")
        liquidity = int.from_bytes(data[96:128], "big")
        tick = int.from_bytes(data[128:160], "big", signed=True)

        swaps.append({
            "tx_hash": log["transactionHash"],
            "block": int(log["blockNumber"], 16),
            "amount0": amount0,
            "amount1": amount1,
            "sqrt_price_x96": sqrt_price,
            "liquidity": liquidity,
            "tick": tick,
        })
    return swaps
```

## Solscan API (Solana)

Solana uses a different architecture — not EVM-compatible. Solscan (now part of Etherscan family) provides REST APIs.

### Key Differences from Etherscan
- No ABI concept — Solana uses "programs" (smart contracts) with IDL (Interface Description Language)
- Accounts are separate from programs (data stored in separate accounts)
- Transactions contain "instructions" (not function calls)
- Token standard is SPL (Solana Program Library), not ERC-20

### Solscan Pro API Endpoints
```
Base URL: https://pro-api.solscan.io/v2.0

GET /account/detail?address=<address>          - Account info
GET /account/transactions?address=<address>    - Transaction history
GET /account/token-accounts?address=<address>  - Token balances
GET /token/meta?address=<mint>                 - Token metadata
GET /token/transfer?address=<mint>             - Token transfers
GET /transaction/detail?tx=<signature>         - Transaction details
```

### Authentication
```python
headers = {"token": os.environ["SOLSCAN_API_KEY"]}
```

### Rate Limits
- Free: 10 requests/second
- Paid: 30-100 requests/second depending on plan

### Raydium / Orca Pool Data on Solana
Pool data for Solana DEXes is typically fetched via:
1. **Solscan API** for historical transactions and token transfers
2. **RPC calls** (`getAccountInfo`, `getProgramAccounts`) for live pool state
3. **DEX SDK** (Raydium SDK, Orca Whirlpool SDK) for structured data access

```python
# Solana pool state via RPC (not explorer API)
import httpx

async def get_solana_account(rpc_url: str, address: str) -> dict:
    """Fetch Solana account data via JSON-RPC."""
    async with httpx.AsyncClient() as client:
        response = await client.post(rpc_url, json={
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getAccountInfo",
            "params": [address, {"encoding": "base64"}],
        })
        return response.json()["result"]
```
