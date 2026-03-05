# Uniswap v4 Deep Mechanics

Referenced from `SKILL.md`. Read this file when working with Uniswap v4 hooks, singleton architecture, or flash accounting.

Last verified: 2026-03-05 | Uniswap v4 launched: January 31, 2025

## Singleton Pool Architecture

### PoolManager Contract
All pools live in a single `PoolManager` contract — no separate contracts per pool.

**Benefits:**
- Dramatically lower gas for multi-pool operations (no inter-contract calls)
- Flash accounting reduces token transfers to net settlements
- Simpler pool creation (no factory deploy, just initialize state)

### PoolKey Structure
Every pool is identified by its `PoolKey`:

```solidity
struct PoolKey {
    Currency currency0;     // Lower-address token
    Currency currency1;     // Higher-address token
    uint24 fee;             // Fee tier (or 0x800000 for dynamic fees via hooks)
    int24 tickSpacing;      // Tick granularity
    IHooks hooks;           // Hook contract address (address(0) for no hooks)
}
```

Pool ID is derived: `poolId = keccak256(abi.encode(poolKey))`

```python
# Python: interact via PoolManager
pool_manager = w3.eth.contract(address=POOL_MANAGER_ADDRESS, abi=V4_MANAGER_ABI)

pool_key = {
    "currency0": token0_address,
    "currency1": token1_address,
    "fee": 3000,          # 0.3% or 0x800000 for dynamic
    "tickSpacing": 60,
    "hooks": hook_address,  # address(0) for no hooks
}
```

## Flash Accounting / Delta-Based Accounting

### How It Works
Instead of transferring tokens for each operation (swap, add liquidity, remove liquidity), v4 tracks internal balance changes ("deltas") and only settles net transfers at the end.

### EIP-1153 Transient Storage
- Uses transient storage (TSTORE/TLOAD) — data exists only for the transaction duration
- Cheaper than regular storage (SSTORE/SLOAD)
- Deltas are stored in transient storage, cleared after the transaction

### Execution Flow
```solidity
// 1. Caller unlocks the PoolManager
poolManager.unlock(callbackData);

// 2. Inside the callback, execute multiple operations
function unlockCallback(bytes calldata data) external returns (bytes memory) {
    // Swap on pool A — updates delta
    poolManager.swap(poolKeyA, swapParams, hookData);

    // Add liquidity on pool B — updates delta
    poolManager.modifyLiquidity(poolKeyB, liquidityParams, hookData);

    // Swap on pool C — updates delta
    poolManager.swap(poolKeyC, swapParams2, hookData);

    // 3. Settle: only net token movements are transferred
    // If pool A swap gave you tokenX and pool C swap consumed tokenX,
    // only the net difference is transferred
    poolManager.settle(currency);   // pay tokens owed
    poolManager.take(currency, to, amount);  // receive tokens owed to you
}
```

**Key insight:** Multiple swaps across multiple pools can be combined into a single transaction with minimal token transfers — enabling efficient arbitrage, routing, and complex strategies.

## Hook System Deep Dive

### What Are Hooks
Hooks are external smart contracts that inject custom logic at specific points in a pool's lifecycle. They enable v4 pools to be customized without modifying the core protocol.

### Hook Permissions Encoding
Hook permissions are encoded in the **hook contract's address bits** (last 14 bits):

| Bit | Hook Point |
|-----|------------|
| 13 | beforeInitialize |
| 12 | afterInitialize |
| 11 | beforeAddLiquidity |
| 10 | afterAddLiquidity |
| 9 | beforeRemoveLiquidity |
| 8 | afterRemoveLiquidity |
| 7 | beforeSwap |
| 6 | afterSwap |
| 5 | beforeDonate |
| 4 | afterDonate |
| 3 | beforeSwapReturnDelta |
| 2 | afterSwapReturnDelta |
| 1 | afterAddLiquidityReturnDelta |
| 0 | afterRemoveLiquidityReturnDelta |

The hook contract address must have the correct bits set. Use `CREATE2` with salt mining to deploy at the required address.

### Hook Contract Template
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract DynamicFeeHook is BaseHook {
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,           // We use this for dynamic fees
            afterSwap: false,
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
        // Example: higher fee during high-volatility periods
        uint24 dynamicFee = _calculateDynamicFee(key);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynamicFee | uint24(0x400000));
        // 0x400000 flag tells PoolManager to use this fee instead of pool's default
    }

    function _calculateDynamicFee(PoolKey calldata key) internal view returns (uint24) {
        // Custom logic: e.g., TWAP-based volatility detection
        // Return fee in hundredths of a bip (1 = 0.0001%)
        return 3000; // 0.3% default
    }
}
```

### Dynamic Fee Flag
When `fee` in PoolKey is set to `0x800000` (bit 23 set), the pool uses dynamic fees:
- `beforeSwap` hook MUST be enabled
- Hook returns the actual fee via the third return value
- Enables volatility-adjusted fees, time-based fees, or oracle-driven pricing

## Hook Use Cases

### 1. Custom AMM Curves
Replace constant-product formula with oracle-based pricing, Curve-style stable pools, or any custom invariant.

### 2. MEV Redistribution
`afterSwap` hook captures MEV value and redistributes to LPs instead of searchers:
- Detect arbitrage swaps by comparing to external oracle
- Charge higher fee on arbitrage trades
- Distribute extra fees to LPs

### 3. On-Chain Limit Orders
`afterSwap` hook places limit orders that execute when price reaches target:
- Store order: (tick, amount, direction)
- When swap crosses the target tick, execute the limit order
- No off-chain infrastructure needed

### 4. TWAMM (Time-Weighted Average Market Maker)
Split large orders into small trades executed over time:
- `beforeSwap` processes pending TWAMM orders
- Reduces price impact for large trades
- Virtual orders executed lazily

### 5. Volatility-Based Dynamic Fees
Higher fees during volatile periods, lower during stable:
- Track price movements via `afterSwap`
- Calculate realized volatility over rolling window
- Adjust fee tier dynamically in `beforeSwap`

## Python Orchestration for v4

```python
from web3 import AsyncWeb3
from eth_abi import encode, decode


class UniswapV4Client:
    """Client for interacting with Uniswap v4 PoolManager."""

    def __init__(self, w3: AsyncWeb3, pool_manager_address: str):
        self.w3 = w3
        self.manager = w3.eth.contract(
            address=pool_manager_address, abi=V4_MANAGER_ABI
        )

    async def get_pool_state(self, pool_key: dict) -> dict:
        """Get current pool state (tick, sqrtPrice, liquidity)."""
        pool_id = self._compute_pool_id(pool_key)

        # slot0: sqrtPriceX96, tick, protocolFee, lpFee
        slot0 = await self.manager.functions.getSlot0(pool_id).call()
        liquidity = await self.manager.functions.getLiquidity(pool_id).call()

        return {
            "pool_id": pool_id.hex(),
            "sqrt_price_x96": slot0[0],
            "tick": slot0[1],
            "protocol_fee": slot0[2],
            "lp_fee": slot0[3],
            "liquidity": liquidity,
        }

    async def get_pool_liquidity_at_tick(self, pool_id: bytes, tick: int) -> dict:
        """Get tick-level liquidity info."""
        tick_info = await self.manager.functions.getTickInfo(pool_id, tick).call()
        return {
            "liquidity_gross": tick_info[0],
            "liquidity_net": tick_info[1],
            "fee_growth_outside_0": tick_info[2],
            "fee_growth_outside_1": tick_info[3],
        }

    def _compute_pool_id(self, pool_key: dict) -> bytes:
        """Compute pool ID from PoolKey (keccak256 of encoded key)."""
        encoded = encode(
            ["address", "address", "uint24", "int24", "address"],
            [
                pool_key["currency0"],
                pool_key["currency1"],
                pool_key["fee"],
                pool_key["tickSpacing"],
                pool_key["hooks"],
            ],
        )
        return self.w3.keccak(encoded)
```

## Deployment Addresses

Uniswap v4 launched January 31, 2025 on 13 networks:

| Chain | PoolManager Address |
|-------|-------------------|
| Ethereum | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Base | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Arbitrum | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Optimism | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Polygon | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| BNB Chain | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Avalanche | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Blast | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| World Chain | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Zora | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Unichain | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| ZKsync | TBD — verify at docs.uniswap.org |

Note: v4 uses CREATE2 deterministic deployment, so the PoolManager address is the same across most chains.

Full deployment list: https://docs.uniswap.org/contracts/v4/deployments
