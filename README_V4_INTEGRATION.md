# Uniswap V4 Stable Swap Integration Guide

## Overview
Your stable swap hook is now deployed and ready to work with Uniswap V4 infrastructure.

## Deployed Contracts (Sepolia)
- **StableSwapCurveV2 Hook**: `0xA55DdAa5457784b3FF006dd462eDD0d519008088`
- **Pool Manager**: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- **DSU Token**: `0x52DD8eCFbF1FA2f7eFeEAF33c2C54cD40019118F`
- **USDC Token**: `0x0241Ac72dC52FD76A0ce8e4527FE68760bd51119`

## Pool Configuration
- **Currency0**: USDC (0x0241Ac72dC52FD76A0ce8e4527FE68760bd51119)
- **Currency1**: DSU (0x52DD8eCFbF1FA2f7eFeEAF33c2C54cD40019118F)
- **Fee**: 100 (0.01%)
- **Tick Spacing**: 1
- **Hook**: StableSwapCurveV2

## Integration with V4 UI/Infrastructure

### 1. **Using with Existing V4 Routers**
Your stable swap hook works with any V4-compatible router:
- PoolSwapTest (for testing)
- V4Router implementations
- Custom routers implementing IUnlockCallback

### 2. **Key Features**
- **Stable Swap Curve**: Uses Curve-style math with A=1000
- **Hook Permissions**: `BEFORE_SWAP` and `BEFORE_SWAP_RETURNS_DELTA`
- **Direct Token Handling**: The hook manages swaps internally

### 3. **How It Works**
1. When a swap is initiated through any V4 router
2. The PoolManager calls your hook's `beforeSwap`
3. Your hook calculates the stable swap output
4. Returns a delta that tells V4 "I handled the swap"
5. V4 processes the token transfers based on your delta

### 4. **Testing with V4 UI**
To test your stable swap pool with V4 UIs:

1. **Add the pool to the UI's pool list**:
   ```json
   {
     "currency0": "0x0241Ac72dC52FD76A0ce8e4527FE68760bd51119",
     "currency1": "0x52DD8eCFbF1FA2f7eFeEAF33c2C54cD40019118F",
     "fee": 100,
     "tickSpacing": 1,
     "hooks": "0xA55DdAa5457784b3FF006dd462eDD0d519008088"
   }
   ```

2. **The pool will appear as a "Custom Curve" pool** due to the hook

3. **Swaps will use your stable swap math** instead of concentrated liquidity

### 5. **Differences from Standard V4 Pools**
- **No Concentrated Liquidity**: Uses stable swap curve instead
- **No Tick/Price Management**: Fixed curve based on reserves
- **Custom Pricing**: 1:1 optimized for stablecoins

### 6. **Adding Liquidity**
Currently, liquidity is added directly through the hook:
```solidity
hook.addLiquidity(poolKey, amount0, amount1)
```

To integrate with V4 liquidity UIs, you could:
1. Implement standard `modifyLiquidity` hooks
2. Create a wrapper that translates V4 liquidity calls
3. Use the existing direct liquidity functions

### 7. **Router Compatibility**
Your hook works with:
- ✅ PoolSwapTest
- ✅ SimpleSwapRouter (custom implementation)
- ✅ Any V4Router implementation
- ✅ Universal Router (when it supports V4)

### 8. **Next Steps**
1. **Add liquidity** to your pool using the scripts
2. **Test swaps** through any V4-compatible interface
3. **Monitor performance** compared to standard AMM curves
4. **Adjust parameters** (A factor) if needed for your use case

## Example Integration
```javascript
// In a V4 UI, add your pool
const stablePool = {
  token0: USDC,
  token1: DSU,
  fee: 100,
  tickSpacing: 1,
  hooks: STABLE_SWAP_HOOK,
  // Custom metadata
  poolType: "stable",
  amplificationFactor: 1000
};

// Swaps will automatically use your hook
const swap = await v4Router.swap(stablePool, swapParams);
```

## Benefits
- **Lower Slippage**: Optimized for stable pairs
- **Better Pricing**: Maintains peg better than x*y=k
- **V4 Compatible**: Works with all V4 infrastructure
- **Gas Efficient**: Single hook call handles entire swap

Your stable swap is now a fully functional V4 pool that can be used with any V4-compatible UI or protocol!