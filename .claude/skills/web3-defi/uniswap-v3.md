# Uniswap v3 Deep Mechanics

Referenced from `SKILL.md`. Read this file when working with Uniswap v3 concentrated liquidity internals.

Last verified: 2026-03-05

## Tick System

### Tick Basics
- Each tick `i` represents a price point: `price = 1.0001^i`
- Tick 0 = price 1.0; positive ticks = higher prices; negative ticks = lower prices
- Not every tick can be initialized — only ticks divisible by `tickSpacing`

### Tick Spacing per Fee Tier
| Fee Tier | Fee (bps) | tickSpacing | Use Case |
|----------|-----------|-------------|----------|
| 100 | 1 | 1 | Ultra-stable (USDC/USDT) |
| 500 | 5 | 10 | Stable pairs |
| 3000 | 30 | 60 | Standard volatility (ETH/USDC) |
| 10000 | 100 | 200 | High volatility / exotic |

### Tick Bitmap
- Compressed storage tracking which ticks are initialized (have liquidity)
- Organized as a mapping: `int16 -> uint256` (256 ticks per word)
- Word position: `tick / 256`, bit position: `tick % 256`
- Enables efficient "find next initialized tick" lookups during swaps

### State Representation
Instead of tracking reserves (x, y) like Uniswap v2, v3 tracks:
- **`sqrtPriceX96`**: current price as `sqrt(price) * 2^96` (Q64.96 fixed-point)
- **`liquidity` (L)**: total active liquidity at current tick
- Between adjacent initialized ticks, the pool follows `x * y = L^2`

```python
def sqrt_price_x96_to_price(sqrt_price_x96: int, decimals0: int, decimals1: int) -> float:
    """Convert sqrtPriceX96 to human-readable price."""
    sqrt_price = sqrt_price_x96 / (2 ** 96)
    raw_price = sqrt_price ** 2
    return raw_price * (10 ** decimals0) / (10 ** decimals1)

def price_to_sqrt_price_x96(price: float, decimals0: int, decimals1: int) -> int:
    """Convert human-readable price to sqrtPriceX96."""
    adjusted = price * (10 ** decimals1) / (10 ** decimals0)
    return int(adjusted ** 0.5 * (2 ** 96))
```

### Crossing Ticks
When a swap moves the price across an initialized tick:
1. The tick's `liquidityNet` delta is applied to active liquidity
2. `feeGrowthOutside` values are flipped: `feeGrowthOutside = feeGrowthGlobal - feeGrowthOutside`
3. The pool continues with updated liquidity for the next tick range

```python
# Pseudocode for tick crossing
def cross_tick(tick: int, fee_growth_global_0: int, fee_growth_global_1: int):
    tick_info = ticks[tick]
    tick_info.fee_growth_outside_0 = fee_growth_global_0 - tick_info.fee_growth_outside_0
    tick_info.fee_growth_outside_1 = fee_growth_global_1 - tick_info.fee_growth_outside_1
    liquidity += tick_info.liquidity_net  # Add or subtract depending on direction
```

## Position NFT Lifecycle

### NonfungiblePositionManager Contract
All LP positions in Uniswap v3 are represented as NFTs managed by this contract.

### Mint (Open Position)
```python
from web3 import AsyncWeb3

NFT_MANAGER_ABI = [...]  # NonfungiblePositionManager ABI

async def mint_position(
    w3: AsyncWeb3,
    nft_manager_address: str,
    token0: str,
    token1: str,
    fee: int,
    tick_lower: int,
    tick_upper: int,
    amount0_desired: int,
    amount1_desired: int,
    recipient: str,
    deadline: int,
    slippage_pct: float = 0.5,
) -> dict:
    """Mint a new Uniswap v3 LP position NFT."""
    nft_manager = w3.eth.contract(address=nft_manager_address, abi=NFT_MANAGER_ABI)

    amount0_min = int(amount0_desired * (1 - slippage_pct / 100))
    amount1_min = int(amount1_desired * (1 - slippage_pct / 100))

    params = {
        "token0": token0,
        "token1": token1,
        "fee": fee,
        "tickLower": tick_lower,
        "tickUpper": tick_upper,
        "amount0Desired": amount0_desired,
        "amount1Desired": amount1_desired,
        "amount0Min": amount0_min,
        "amount1Min": amount1_min,
        "recipient": recipient,
        "deadline": deadline,
    }

    tx = await nft_manager.functions.mint(params).build_transaction({
        "from": recipient,
        "gas": 500_000,
    })
    return tx
```

### Collect Fees
```python
async def collect_fees(
    w3: AsyncWeb3,
    nft_manager_address: str,
    token_id: int,
    recipient: str,
) -> dict:
    """Collect accumulated fees for a position."""
    nft_manager = w3.eth.contract(address=nft_manager_address, abi=NFT_MANAGER_ABI)

    params = {
        "tokenId": token_id,
        "recipient": recipient,
        "amount0Max": 2**128 - 1,  # MAX_UINT128
        "amount1Max": 2**128 - 1,
    }

    tx = await nft_manager.functions.collect(params).build_transaction({
        "from": recipient,
        "gas": 200_000,
    })
    return tx
```

### Close Position (Decrease + Collect + Burn)
```python
async def close_position(
    w3: AsyncWeb3,
    nft_manager_address: str,
    token_id: int,
    liquidity: int,
    recipient: str,
    deadline: int,
) -> list[dict]:
    """Close a position: remove liquidity, collect tokens + fees, burn NFT."""
    nft_manager = w3.eth.contract(address=nft_manager_address, abi=NFT_MANAGER_ABI)
    txs = []

    # 1. Remove all liquidity
    decrease_params = {
        "tokenId": token_id,
        "liquidity": liquidity,
        "amount0Min": 0,
        "amount1Min": 0,
        "deadline": deadline,
    }
    txs.append(await nft_manager.functions.decreaseLiquidity(decrease_params).build_transaction({
        "from": recipient, "gas": 300_000,
    }))

    # 2. Collect tokens + fees
    collect_params = {
        "tokenId": token_id,
        "recipient": recipient,
        "amount0Max": 2**128 - 1,
        "amount1Max": 2**128 - 1,
    }
    txs.append(await nft_manager.functions.collect(collect_params).build_transaction({
        "from": recipient, "gas": 200_000,
    }))

    # 3. Burn the NFT (only if liquidity = 0 and fees = 0)
    txs.append(await nft_manager.functions.burn(token_id).build_transaction({
        "from": recipient, "gas": 100_000,
    }))

    return txs
```

## Fee Growth Tracking Internals

### Global Fee Accumulators
- `feeGrowthGlobal0X128`: cumulative fees earned per unit of liquidity for token0
- `feeGrowthGlobal1X128`: cumulative fees earned per unit of liquidity for token1
- Format: Q128.128 fixed-point — multiply by `2^128` for integer storage
- Updated on every swap: `feeGrowthGlobal += fee_amount / active_liquidity`

### Per-Tick Fee Tracking
Each initialized tick stores:
- `feeGrowthOutside0X128`: fee growth on the "other side" of this tick
- `feeGrowthOutside1X128`: same for token1

### Initialization Rule
When a tick is first initialized (liquidity added):
- If `tick <= currentTick`: `feeGrowthOutside = feeGrowthGlobal` (all past fees attributed to "below")
- If `tick > currentTick`: `feeGrowthOutside = 0` (no past fees attributed to "above")

### Fee Growth Inside Calculation
For a position between `tickLower` and `tickUpper`:

```python
def calculate_fee_growth_inside(
    current_tick: int,
    tick_lower: int,
    tick_upper: int,
    fee_growth_global: int,
    fee_growth_outside_lower: int,
    fee_growth_outside_upper: int,
) -> int:
    """Calculate fee growth inside a position's tick range.

    The meaning of feeGrowthOutside depends on which side of the tick
    the current price is on. This function handles all three cases:
    - Current tick inside range: subtract both outsides from global
    - Current tick below range: fees between ticks = lower_outside - upper_outside
    - Current tick above range: fees between ticks = upper_outside - lower_outside
    """
    # Fee growth below the lower tick
    if current_tick >= tick_lower:
        fee_growth_below = fee_growth_outside_lower
    else:
        fee_growth_below = fee_growth_global - fee_growth_outside_lower

    # Fee growth above the upper tick
    if current_tick < tick_upper:
        fee_growth_above = fee_growth_outside_upper
    else:
        fee_growth_above = fee_growth_global - fee_growth_outside_upper

    # Fee growth inside = global - below - above
    # Handle uint256 underflow with modular arithmetic
    return (fee_growth_global - fee_growth_below - fee_growth_above) % (2 ** 256)
```

### Uncollected Fees for a Position
```python
def calculate_uncollected_fees(
    liquidity: int,
    fee_growth_inside_current: int,
    fee_growth_inside_last: int,
) -> float:
    """Calculate uncollected fees since last collection.

    fee_growth_inside_current: current fee growth inside the position range
    fee_growth_inside_last: fee growth inside at last collect/mint (stored in position)
    """
    delta = (fee_growth_inside_current - fee_growth_inside_last) % (2 ** 256)
    return delta * liquidity / (2 ** 128)
```

### Complete Fee Calculation Pipeline
```python
async def get_position_fees(
    w3: AsyncWeb3,
    pool_address: str,
    tick_lower: int,
    tick_upper: int,
    liquidity: int,
    fee_growth_inside_0_last: int,
    fee_growth_inside_1_last: int,
) -> tuple[float, float]:
    """Full pipeline to calculate uncollected fees for a position."""
    pool = w3.eth.contract(address=pool_address, abi=UNISWAP_V3_POOL_ABI)

    # Fetch current state
    slot0 = await pool.functions.slot0().call()
    current_tick = slot0[1]
    fg_global_0 = await pool.functions.feeGrowthGlobal0X128().call()
    fg_global_1 = await pool.functions.feeGrowthGlobal1X128().call()

    # Fetch tick data
    lower_data = await pool.functions.ticks(tick_lower).call()
    upper_data = await pool.functions.ticks(tick_upper).call()

    # Calculate fee growth inside for both tokens
    fg_inside_0 = calculate_fee_growth_inside(
        current_tick, tick_lower, tick_upper,
        fg_global_0, lower_data[2], upper_data[2],  # feeGrowthOutside0X128
    )
    fg_inside_1 = calculate_fee_growth_inside(
        current_tick, tick_lower, tick_upper,
        fg_global_1, lower_data[3], upper_data[3],  # feeGrowthOutside1X128
    )

    fees_0 = calculate_uncollected_fees(liquidity, fg_inside_0, fee_growth_inside_0_last)
    fees_1 = calculate_uncollected_fees(liquidity, fg_inside_1, fee_growth_inside_1_last)

    return fees_0, fees_1
```

## Capital Efficiency Mathematics

### Concentrated vs Full-Range Liquidity
In Uniswap v2, liquidity is spread from price 0 to infinity. In v3, LPs concentrate liquidity in a range `[pa, pb]`.

**Capital efficiency multiplier:**
```
efficiency = 1 / (1 - sqrt(pa/pb))
```

Example: ETH/USDC pool, current price = 2000 USDC
- Range [1800, 2200]: efficiency = ~7.3x
- Range [1900, 2100]: efficiency = ~14.5x
- Range [1950, 2050]: efficiency = ~29x

### How Concentration Amplifies IL
Concentrated liquidity amplifies BOTH fee earnings AND impermanent loss:

```python
def concentrated_il(
    price_ratio: float,
    tick_lower: int,
    tick_upper: int,
    decimals0: int,
    decimals1: int,
) -> float:
    """Calculate IL for a concentrated liquidity position.

    IL is amplified proportionally to the concentration factor.
    If price exits the range, the position is 100% one token (maximum IL for that range).
    """
    pa = tick_to_price(tick_lower, decimals0, decimals1)
    pb = tick_to_price(tick_upper, decimals0, decimals1)
    p = pa * price_ratio  # current price assuming pa was entry price

    if p <= pa:
        # Below range: position is 100% token1, max IL for this range
        return (2 * (pa * pb) ** 0.5 / (pa + pb)) - 1
    elif p >= pb:
        # Above range: position is 100% token0, max IL for this range
        return (2 * (pa * pb) ** 0.5 / (pa + pb)) - 1
    else:
        # In range: amplified IL
        numerator = 2 * (p * pb) ** 0.5 - p - pb
        denominator = p + pb - 2 * (p * pa) ** 0.5
        # Simplified: use concentration factor * standard IL
        standard_il = 2 * price_ratio ** 0.5 / (1 + price_ratio) - 1
        concentration = 1 / (1 - (pa / pb) ** 0.5)
        return standard_il * concentration
```

### Decision Framework
| Range Width | Efficiency | IL Risk | Best For |
|-------------|-----------|---------|----------|
| Full range | 1x | Low | Set-and-forget, volatile pairs |
| +/- 20% | ~3x | Medium | Medium-term positions |
| +/- 10% | ~5x | High | Active management, stable pairs |
| +/- 2% | ~25x | Very high | Stablecoins, professional LPs |

## Contract Addresses (Ethereum Mainnet)

| Contract | Address |
|----------|---------|
| UniswapV3Factory | `0x1F98431c8aD98523631AE4a59f267346ea31F984` |
| SwapRouter | `0xE592427A0AEce92De3Edee1F18E0157C05861564` |
| SwapRouter02 | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| NonfungiblePositionManager | `0xC36442b4a4522E871399CD717aBDD847Ab11FE88` |
| Quoter | `0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6` |
| QuoterV2 | `0x61fFE014bA17989E743c5F6cB21bF9697530B21e` |

### Multi-Chain Deployment
The same contracts are deployed on: Polygon, Arbitrum, Optimism, Base, BNB Chain, Celo, Avalanche, Blast, ZKsync.
Addresses may differ per chain — verify via https://docs.uniswap.org/contracts/v3/reference/deployments/
