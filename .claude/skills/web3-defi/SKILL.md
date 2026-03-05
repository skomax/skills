---
name: web3-defi
description: Web3, DeFi, and blockchain development. Uniswap v3/v4 liquidity pools, on-chain data, multi-chain support (Ethereum, BNB, Base, Solana), Python web3.py, and Solidity patterns.
---

# Web3 & DeFi Development Skill

## When to Activate
- Working with blockchain, smart contracts, DeFi protocols
- Uniswap liquidity pool simulation or interaction
- On-chain data fetching and processing
- Multi-chain development (Ethereum, BNB Chain, Base, Arbitrum, Solana)
- Token/pool analytics and strategy calculations
- Block explorer API integration

## Key Libraries

| Library | Language | Use Case |
|---------|----------|----------|
| **web3.py 7+** | Python | Ethereum node interaction, contract calls |
| **eth-abi** | Python | ABI encoding/decoding |
| **eth-defi** | Python | DeFi protocol wrappers (Uniswap, Aave) |
| **ethers.js 6.x** | JS/TS | Frontend/backend chain interaction |
| **viem 2.x** | TS | Modern alternative to ethers, better types |
| **foundry** | Solidity | Smart contract development, testing |
| **hardhat** | JS/TS | Smart contract development, deployment |
| **solana-py** | Python | Solana RPC interaction |
| **solders** | Python | Solana data structures, keypairs |

## Sub-Files (read when working on specific topics)
- **`uniswap-v3.md`** — Tick system, position NFT lifecycle, fee growth internals, capital efficiency math, contract addresses
- **`uniswap-v4.md`** — Singleton architecture, flash accounting, hooks deep dive, dynamic fees, deployment addresses
- **`explorer-apis.md`** — Etherscan/BscScan/BaseScan/Solscan API structure, Python client, DeFi data patterns

## Uniswap v3 Liquidity Pool Concepts

### Core Parameters
```python
@dataclass
class PoolPosition:
    pool_address: str
    token0: str          # Lower-sorted token address
    token1: str          # Higher-sorted token address
    fee: int             # Fee tier: 100 (0.01%), 500 (0.05%), 3000 (0.3%), 10000 (1%)
    tick_lower: int      # Lower price boundary
    tick_upper: int      # Upper price boundary
    liquidity: int       # Liquidity amount
    token0_amount: float # Deposited amount of token0
    token1_amount: float # Deposited amount of token1
```

### Price-Tick Conversion
```python
import math

def price_to_tick(price: float, decimals0: int, decimals1: int) -> int:
    """Convert human-readable price to Uniswap v3 tick."""
    adjusted_price = price * (10 ** decimals0) / (10 ** decimals1)
    return int(math.floor(math.log(adjusted_price, 1.0001)))

def tick_to_price(tick: int, decimals0: int, decimals1: int) -> float:
    """Convert tick to human-readable price."""
    raw_price = 1.0001 ** tick
    return raw_price * (10 ** decimals1) / (10 ** decimals0)

def tick_to_sqrt_price_x96(tick: int) -> int:
    """Convert tick to sqrtPriceX96 format."""
    return int((1.0001 ** (tick / 2)) * (2 ** 96))
```

### Fee Calculation
For the complete fee calculation pipeline with fee growth internals, see `uniswap-v3.md`.

Quick reference — fee tiers and tick spacing:
| Fee | Bps | tickSpacing | Use Case |
|-----|-----|-------------|----------|
| 100 | 1 | 1 | Ultra-stable (USDC/USDT) |
| 500 | 5 | 10 | Stable pairs |
| 3000 | 30 | 60 | Standard (ETH/USDC) |
| 10000 | 100 | 200 | High volatility |

## Uniswap Protocol Fees (UNIfication — December 2025)

Since the UNIfication governance vote (December 25, 2025), Uniswap has a transparent protocol fee layer:

### Fee Split Structure
| Pool Type | Total Fee | LP Share | Protocol Share | Protocol % |
|-----------|-----------|----------|----------------|------------|
| V2 pools | 0.30% | 0.25% | 0.05% | 16.7% |
| Low-fee (0.01-0.05%) | varies | 75% | 25% | 25% |
| Standard (0.3%) | 0.30% | 0.25% | 0.05% | 16.7% |
| High-vol (1%) | 1.00% | 0.833% | 0.167% | 16.7% |

### Where Protocol Revenue Goes
- Revenue directed to **UNI token buyback and burn** (on-chain, transparent)
- Executed via governance-controlled contracts with 2-day timelock

### Frontend Fee History
- Uniswap Labs previously charged a **0.25% frontend/interface fee** on swaps via their web app
- After UNIfication, the web interface fee was **set to zero**
- Protocol-level fees replaced interface-level fees

### Impact on LP Calculations
When calculating expected LP returns, account for the protocol fee:
```python
def effective_lp_fee_rate(fee_tier: int) -> float:
    """Calculate the actual fee rate LPs receive after protocol cut."""
    protocol_share = 0.25 if fee_tier <= 500 else 0.167
    return fee_tier / 1_000_000 * (1 - protocol_share)

# Example: 0.3% pool -> LPs earn 0.25% per swap (not 0.3%)
```

## Out-of-Range Position Behavior

### No Liquidation
Uniswap v3 positions are **never liquidated**. When price exits your range, the position simply stops earning fees.

### Token Composition at Boundaries
```
Price BELOW tickLower:  Position = 100% token1, 0% token0
Price IN RANGE:         Position = mix of token0 and token1
Price ABOVE tickUpper:  Position = 100% token0, 0% token1
```

Think of it as a limit order that gradually executes:
- If you provide ETH/USDC liquidity in range [1800, 2200]:
  - Price drops to 1500: you hold 100% ETH (bought ETH as price fell)
  - Price rises to 2500: you hold 100% USDC (sold ETH as price rose)

### Token Amounts at Boundaries
```python
def token_amounts_at_price(
    liquidity: int,
    sqrt_price_x96: int,
    tick_lower: int,
    tick_upper: int,
) -> tuple[int, int]:
    """Calculate token0 and token1 amounts for a position at current price."""
    sqrt_a = tick_to_sqrt_price_x96(tick_lower) / (2**96)
    sqrt_b = tick_to_sqrt_price_x96(tick_upper) / (2**96)
    sqrt_p = sqrt_price_x96 / (2**96)

    if sqrt_p <= sqrt_a:
        # Below range: all token0
        amount0 = int(liquidity * (1/sqrt_a - 1/sqrt_b))
        amount1 = 0
    elif sqrt_p >= sqrt_b:
        # Above range: all token1
        amount0 = 0
        amount1 = int(liquidity * (sqrt_b - sqrt_a))
    else:
        # In range: both tokens
        amount0 = int(liquidity * (1/sqrt_p - 1/sqrt_b))
        amount1 = int(liquidity * (sqrt_p - sqrt_a))

    return amount0, amount1
```

### Rebalance vs Hold Decision
| Factor | Rebalance | Hold (Wait) |
|--------|-----------|-------------|
| Gas costs | High (remove + swap + add) | Zero |
| Expected return to range | Unlikely | Likely |
| Time out of range | Long (>24h) | Short (<1h) |
| IL accumulated | Significant | Minimal |
| Gas prices | Low (<30 gwei) | High (>100 gwei) |

Rule of thumb: Rebalance when `expected_fee_earnings > rebalance_cost * 2`.

## Pool Simulation Strategy
```python
@dataclass
class SimulationConfig:
    initial_investment_usd: float
    pool_address: str
    fee_tier: int
    price_range_lower: float   # e.g., -5% from current
    price_range_upper: float   # e.g., +5% from current
    duration_days: int
    reinvest: bool = False     # Reinvestment mode
    rebalance: bool = False    # Moving pool mode
    rebalance_trigger: str = "price_exit"  # or "time_based", "volatility"
    rebalance_max_count: int = 10
    slippage_tolerance: float = 0.005  # 0.5%
    gas_estimate_gwei: float = 30.0

class PoolSimulator:
    def __init__(self, config: SimulationConfig, historical_data: pd.DataFrame):
        self.config = config
        self.data = historical_data  # columns: timestamp, price, volume, liquidity

    def run_simulation(self) -> SimulationResult:
        """Run full simulation over historical data."""
        position = self._open_position(self.data.iloc[0])

        for row in self.data.itertuples():
            if self._is_price_out_of_range(row.price, position):
                if self.config.rebalance:
                    position = self._rebalance(position, row)
                else:
                    position.active = False
            else:
                position = self._accrue_fees(position, row)

            if self.config.reinvest and position.pending_fees_usd > threshold:
                position = self._reinvest_fees(position)

        return self._calculate_results(position)
```

## On-Chain Data Fetching

### Using web3.py (async)
```python
from web3 import AsyncWeb3

# Multi-chain RPC endpoints
CHAINS = {
    "ethereum": "https://eth-mainnet.g.alchemy.com/v2/{API_KEY}",
    "bnb": "https://bsc-dataseed.binance.org",
    "base": "https://mainnet.base.org",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
    "polygon": "https://polygon-rpc.com",
    "solana": "https://api.mainnet-beta.solana.com",  # Not web3.py — use solana-py
}

async def get_pool_data(chain: str, pool_address: str, decimals0: int = 6, decimals1: int = 18) -> dict:
    w3 = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(CHAINS[chain]))
    pool_contract = w3.eth.contract(address=pool_address, abi=UNISWAP_V3_POOL_ABI)

    slot0 = await pool_contract.functions.slot0().call()
    liquidity = await pool_contract.functions.liquidity().call()

    # Convert sqrtPriceX96 to human-readable price (accounting for token decimals)
    sqrt_price = slot0[0] / (2**96)
    raw_price = sqrt_price ** 2
    price = raw_price * (10 ** decimals0) / (10 ** decimals1)

    return {
        "sqrt_price_x96": slot0[0],
        "tick": slot0[1],
        "liquidity": liquidity,
        "price": price,
    }
```

### Historical Data Collection
```python
async def collect_pool_history(
    pool_address: str,
    from_block: int,
    to_block: int,
    batch_size: int = 1000,
) -> pd.DataFrame:
    """Collect swap events for historical analysis."""
    events = []
    for start in range(from_block, to_block, batch_size):
        end = min(start + batch_size, to_block)
        batch = pool_contract.events.Swap.get_logs(fromBlock=start, toBlock=end)
        events.extend(batch)
    return pd.DataFrame([parse_swap_event(e) for e in events])
```

## Moving/Rebalancing Pool Strategy

When price exits the position range, the pool stops earning fees. A rebalancing strategy
recreates the position around the new price.

```python
@dataclass
class RebalanceConfig:
    trigger: str = "price_exit"       # price_exit | time_interval | volatility_spike
    cooldown_seconds: int = 3600      # Min time between rebalances
    max_rebalances: int = 20          # Circuit breaker
    gas_threshold_gwei: float = 50.0  # Skip rebalance if gas too high
    min_remaining_value_pct: float = 0.95  # Stop if IL erodes >5%
    range_width_pct: float = 5.0      # New range: +/- 5% from current price
    center_offset_pct: float = 0.0    # Shift center for directional bias

class RebalancingStrategy:
    def __init__(self, config: RebalanceConfig, pool: PoolPosition):
        self.config = config
        self.pool = pool
        self.rebalance_count = 0
        self.last_rebalance_time = 0

    def should_rebalance(self, current_price: float, current_time: int, gas_gwei: float) -> bool:
        if self.rebalance_count >= self.config.max_rebalances:
            return False  # Circuit breaker
        if current_time - self.last_rebalance_time < self.config.cooldown_seconds:
            return False  # Cooldown
        if gas_gwei > self.config.gas_threshold_gwei:
            return False  # Gas too expensive

        if self.config.trigger == "price_exit":
            return not self._is_in_range(current_price)
        elif self.config.trigger == "time_interval":
            return current_time - self.last_rebalance_time >= self.config.cooldown_seconds
        elif self.config.trigger == "volatility_spike":
            return self._volatility_exceeds_threshold()
        return False

    def calculate_new_range(self, current_price: float) -> tuple[float, float]:
        """Calculate new tick range centered on current price."""
        center = current_price * (1 + self.config.center_offset_pct / 100)
        half_width = center * self.config.range_width_pct / 100
        return (center - half_width, center + half_width)

    def estimate_rebalance_cost(self, gas_gwei: float) -> float:
        """Estimate total cost: gas for remove + swap + add liquidity."""
        gas_units = 350_000  # ~150k remove + 100k swap + 100k add
        return gas_units * gas_gwei * 1e-9  # Cost in ETH

    def _is_in_range(self, price: float) -> bool:
        lower = tick_to_price(self.pool.tick_lower, 6, 18)
        upper = tick_to_price(self.pool.tick_upper, 6, 18)
        return lower <= price <= upper
```

### Impermanent Loss Calculator
```python
def calculate_impermanent_loss(
    price_ratio: float,  # current_price / entry_price
) -> float:
    """Calculate IL as percentage loss vs holding (x*y=k AMM formula).
    price_ratio = 1.0 means no change, 2.0 means price doubled.
    Returns negative value (e.g., -0.057 = 5.7% loss).
    NOTE: For Uniswap v3 concentrated liquidity, IL is amplified
    proportionally to the concentration factor. This formula gives
    a lower bound; actual IL depends on the position's tick range.
    See uniswap-v3.md for concentrated_il() function.
    """
    return 2 * math.sqrt(price_ratio) / (1 + price_ratio) - 1

def net_pnl_vs_hold(
    entry_price: float,
    exit_price: float,
    fees_earned_usd: float,
    initial_investment_usd: float,
    gas_costs_usd: float,
) -> float:
    """Compare LP position vs simple hold strategy."""
    price_ratio = exit_price / entry_price
    il_pct = calculate_impermanent_loss(price_ratio)
    il_usd = initial_investment_usd * abs(il_pct)
    return fees_earned_usd - il_usd - gas_costs_usd
```

## Uniswap v4 Architecture

For full v4 documentation see `uniswap-v4.md`. Key concepts:

- **Singleton PoolManager**: All pools in one contract, no factory deployment
- **Flash Accounting**: Delta-based accounting with EIP-1153 transient storage — only net token transfers
- **Hooks**: Custom logic at 14 lifecycle points (beforeSwap, afterSwap, etc.)
- **Dynamic Fees**: Set fee to `0x800000`, hook returns actual fee per swap
- **PoolKey**: `(currency0, currency1, fee, tickSpacing, hooks)` identifies each pool

## Multi-Chain DEX Protocols

| Chain | DEX | Fork Of | Key Difference | Fee Structure |
|-------|-----|---------|----------------|---------------|
| Ethereum | Uniswap v3/v4 | Original | Reference implementation | 0.01-1% (LP share after protocol cut) |
| BNB Chain | PancakeSwap v3 | Uniswap v3 | Lower fees, CAKE rewards | 0.25% total: 0.17% LP, 0.08% protocol |
| Base | Aerodrome | Velodrome/Uni v3 | ve(3,3) tokenomics, vote-directed emissions | Variable, governance-set |
| Arbitrum | Camelot | Custom | Concentrated + volatile pools, spNFT positions | Dual (volatile + stable) |
| Polygon | QuickSwap v3 | Uniswap v3 | Algebra integration, dynamic fees | Dynamic (volatility-based) |
| Solana | Raydium | Custom (not EVM) | AMM on Solana, classic + concentrated | 0.25% standard |
| Solana | Orca | Custom (not EVM) | Whirlpool concentrated liquidity | Variable per pool |
| Unichain | Uniswap v4 | Original | Uniswap's own L2, lowest fees | Same as Uniswap v4 |

### Solana DEX Notes
Solana is **not EVM-compatible** — uses programs (smart contracts), accounts model, and SPL tokens:
- Use `solana-py` or `solders` instead of web3.py
- Raydium: classic pools (x*y=k) and Fusion pools
- Orca: Whirlpool concentrated liquidity (similar concept to Uniswap v3 ticks)
- Pool creation via UI, SDK, or CPI (Cross-Program Invocation)

```python
# Multi-chain pool factory (EVM chains only)
DEX_CONFIGS = {
    "uniswap_v3_eth": {"factory": "0x1F98431c8aD98523631AE4a59f267346ea31F984", "chain": "ethereum", "abi": UNI_V3_ABI},
    "pancake_v3_bnb": {"factory": "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865", "chain": "bnb", "abi": PANCAKE_V3_ABI},
    "aerodrome_base": {"factory": "0x420DD381b31aEf6683db6B902084cB0FFECe40Da", "chain": "base", "abi": AERO_ABI},
}

async def get_pool_across_chains(token_pair: str) -> list[dict]:
    """Find best pool for a pair across all supported EVM chains."""
    results = []
    for dex_name, config in DEX_CONFIGS.items():
        w3 = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(CHAINS[config["chain"]]))
        pool = await find_pool(w3, config, token_pair)
        if pool:
            results.append({"dex": dex_name, **pool})
    return sorted(results, key=lambda x: x["liquidity"], reverse=True)
```

## Flash Loans & Flash Swaps

### Uniswap v3 Flash
Borrow any amount of token0 and/or token1 from a pool, use them, and repay with fee in a single transaction:
```python
# Flash loan fee = pool fee tier (e.g., 0.3% for 3000 tier)
# Must repay: amount + fee within the same transaction
# Use case: arbitrage, liquidations, collateral swaps
```

### Uniswap v4 Flash Accounting
v4's flash accounting makes flash-loan-like patterns native:
- Execute multiple operations in `unlockCallback`
- Only net balances settled at the end
- No need for explicit flash loan contracts

## MEV Protection

### Strategies
- **Flashbots Protect**: Submit transactions via `https://rpc.flashbots.net` instead of public mempool
- **Private mempools**: MEV Blocker (`https://rpc.mevblocker.io`), MEV Share
- **Slippage limits**: Always set `amountOutMin` / `sqrtPriceLimitX96`
- **Deadline parameter**: Set tight deadlines to prevent stale transaction execution

```python
# Using Flashbots Protect RPC
FLASHBOTS_RPC = "https://rpc.flashbots.net"
w3_protected = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(FLASHBOTS_RPC))
# Transactions sent via this RPC are not visible in the public mempool
```

## Multi-Hop Routing

For complex swaps, use DEX aggregators instead of direct pool interaction:

| Aggregator | API | Chains |
|------------|-----|--------|
| **1inch** | `https://api.1inch.dev/swap/v6.0/{chainId}/swap` | All major EVM |
| **0x** | `https://api.0x.org/swap/v1/quote` | All major EVM |
| **Jupiter** | `https://quote-api.jup.ag/v6/quote` | Solana |
| **Paraswap** | `https://apiv5.paraswap.io/prices` | All major EVM |

Aggregators find optimal routing across multiple pools and DEXes, splitting trades for better prices.

## Security Checklist

- [ ] Never log or expose private keys
- [ ] Validate all contract addresses (checksummed)
- [ ] Implement slippage protection for all swaps
- [ ] Check for reentrancy in smart contracts
- [ ] Test on testnet (Sepolia, BSC Testnet) before mainnet
- [ ] Monitor gas prices before transactions
- [ ] Implement circuit breakers for automated strategies
- [ ] Verify token approvals are for exact amounts (not unlimited)
- [ ] Use Flashbots or private mempool for MEV-sensitive transactions
- [ ] Set deadline parameters on all swap transactions

## See Also
- `uniswap-v3.md` — tick system, position NFTs, fee growth internals, capital efficiency
- `uniswap-v4.md` — singleton architecture, flash accounting, hooks, dynamic fees
- `explorer-apis.md` — Etherscan/BscScan/Solscan API reference, Python client
- `database-patterns` skill for storing on-chain data
- `data-processing` skill for historical data analysis
- `docker-devops` skill for deployment of monitoring services
