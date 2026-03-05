---
name: web3-defi
description: Web3, DeFi, and blockchain development. Uniswap v3/v4 liquidity pools, on-chain data, multi-chain support (Ethereum, BNB, Base), Python web3.py, and Solidity patterns.
---

# Web3 & DeFi Development Skill

## When to Activate
- Working with blockchain, smart contracts, DeFi protocols
- Uniswap liquidity pool simulation or interaction
- On-chain data fetching and processing
- Multi-chain development (Ethereum, BNB Chain, Base, Arbitrum)
- Token/pool analytics and strategy calculations

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
```python
def calculate_fees(
    liquidity: int,
    tick_lower: int,
    tick_upper: int,
    current_tick: int,
    fee_growth_global_0: int,
    fee_growth_global_1: int,
    fee_growth_outside_lower_0: int,
    fee_growth_outside_lower_1: int,
    fee_growth_outside_upper_0: int,
    fee_growth_outside_upper_1: int,
) -> tuple[float, float]:
    """Calculate uncollected fees for a position."""
    # Fee growth inside the position range
    if current_tick >= tick_lower and current_tick < tick_upper:
        fee_growth_inside_0 = fee_growth_global_0 - fee_growth_outside_lower_0 - fee_growth_outside_upper_0
        fee_growth_inside_1 = fee_growth_global_1 - fee_growth_outside_lower_1 - fee_growth_outside_upper_1
    # ... handle other cases

    fees_0 = (fee_growth_inside_0 * liquidity) / (2 ** 128)
    fees_1 = (fee_growth_inside_1 * liquidity) / (2 ** 128)
    return fees_0, fees_1
```

### Pool Simulation Strategy
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

        for _, row in self.data.iterrows():
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

### Using web3.py
```python
from web3 import Web3

# Multi-chain RPC endpoints
CHAINS = {
    "ethereum": "https://eth-mainnet.g.alchemy.com/v2/{API_KEY}",
    "bnb": "https://bsc-dataseed.binance.org",
    "base": "https://mainnet.base.org",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
}

async def get_pool_data(chain: str, pool_address: str) -> dict:
    w3 = Web3(Web3.HTTPProvider(CHAINS[chain]))
    pool_contract = w3.eth.contract(address=pool_address, abi=UNISWAP_V3_POOL_ABI)

    slot0 = pool_contract.functions.slot0().call()
    liquidity = pool_contract.functions.liquidity().call()

    return {
        "sqrt_price_x96": slot0[0],
        "tick": slot0[1],
        "liquidity": liquidity,
        "price": (slot0[0] / (2**96)) ** 2,
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
    """Calculate IL as percentage loss vs holding.
    price_ratio = 1.0 means no change, 2.0 means price doubled.
    Returns negative value (e.g., -0.057 = 5.7% loss).
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

### Singleton PoolManager
All pools live in one contract. No separate contracts per pool.
```python
# v3: each pool is a separate contract
pool_v3 = w3.eth.contract(address=POOL_ADDRESS, abi=V3_POOL_ABI)

# v4: interact via PoolManager
pool_manager = w3.eth.contract(address=POOL_MANAGER_ADDRESS, abi=V4_MANAGER_ABI)
pool_key = {
    "currency0": token0_address,
    "currency1": token1_address,
    "fee": 3000,
    "tickSpacing": 60,
    "hooks": hook_contract_address,  # Custom hook
}
```

### Hook Lifecycle Callbacks
```solidity
// Solidity hook contract structure
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

contract MyHook is BaseHook {
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,       // Dynamic fee logic here
            afterSwap: true,        // Analytics, TWAP updates
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Custom logic: dynamic fees based on volatility
        uint24 dynamicFee = calculateDynamicFee(key);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynamicFee);
    }
}
```

### Python Orchestration for v4
```python
class UniswapV4Client:
    def __init__(self, w3: Web3, pool_manager_address: str):
        self.w3 = w3
        self.manager = w3.eth.contract(address=pool_manager_address, abi=V4_MANAGER_ABI)

    def get_pool_state(self, pool_key: dict) -> dict:
        pool_id = self.manager.functions.getPoolId(pool_key).call()
        slot0 = self.manager.functions.getSlot0(pool_id).call()
        liquidity = self.manager.functions.getLiquidity(pool_id).call()
        return {"pool_id": pool_id, "tick": slot0[1], "liquidity": liquidity}

    def simulate_swap(self, pool_key: dict, amount_in: int, zero_for_one: bool) -> int:
        """Simulate swap to estimate output amount."""
        # Use Quoter contract for simulation
        return self.quoter.functions.quoteExactInputSingle(
            pool_key, zero_for_one, amount_in, 0, b""
        ).call()
```

## Multi-Chain DEX Protocols

| Chain | DEX | Fork Of | Key Difference |
|-------|-----|---------|----------------|
| Ethereum | Uniswap v3/v4 | Original | Reference implementation |
| BNB Chain | PancakeSwap v3 | Uniswap v3 | Lower fees, CAKE rewards |
| Base | Aerodrome | Velodrome/Uni v3 | ve(3,3) tokenomics, vote-directed emissions |
| Arbitrum | Camelot | Custom | Concentrated + volatile pools, spNFT positions |
| Polygon | QuickSwap v3 | Uniswap v3 | Algebra integration, dynamic fees |

```python
# Multi-chain pool factory
DEX_CONFIGS = {
    "uniswap_v3_eth": {"factory": "0x1F98...", "chain": "ethereum", "abi": UNI_V3_ABI},
    "pancake_v3_bnb": {"factory": "0x0BF...", "chain": "bnb", "abi": PANCAKE_V3_ABI},
    "aerodrome_base": {"factory": "0x420...", "chain": "base", "abi": AERO_ABI},
}

async def get_pool_across_chains(token_pair: str) -> list[dict]:
    """Find best pool for a pair across all supported chains."""
    results = []
    for dex_name, config in DEX_CONFIGS.items():
        w3 = Web3(Web3.HTTPProvider(CHAINS[config["chain"]]))
        pool = await find_pool(w3, config, token_pair)
        if pool:
            results.append({"dex": dex_name, **pool})
    return sorted(results, key=lambda x: x["liquidity"], reverse=True)
```

## Security Checklist

- [ ] Never log or expose private keys
- [ ] Validate all contract addresses (checksummed)
- [ ] Implement slippage protection for all swaps
- [ ] Check for reentrancy in smart contracts
- [ ] Test on testnet (Sepolia, BSC Testnet) before mainnet
- [ ] Monitor gas prices before transactions
- [ ] Implement circuit breakers for automated strategies
- [ ] Verify token approvals are for exact amounts (not unlimited)
