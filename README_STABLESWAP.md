# StableSwap Curve Deployment Guide

This guide explains how to deploy and test the StableSwap Curve implementation for Uniswap V4 on Sepolia.

## Overview

The StableSwap implementation provides:
- Low slippage swaps between stable assets (DSU/USDC)
- Amplification coefficient A = 1000 for stable price curve
- Full Uniswap V4 hook integration
- CREATE2 deployment for deterministic addresses

## Prerequisites

1. Set up environment variables in `.env`:
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. Ensure you have Sepolia ETH for gas fees

## Deployment

### Step 1: Deploy Contracts

Run the deployment script:

```bash
forge script script/DeployStableSwapCurve.s.sol:DeployStableSwapCurve \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

This will:
1. Deploy mock DSU and USDC tokens
2. Mine a CREATE2 address for the hook with correct permissions
3. Deploy the StableSwapCurve hook
4. Initialize the pool with 1:1 price
5. Add initial liquidity (100K of each token)
6. Execute a test swap

### Step 2: Save Deployed Addresses

After deployment, save the contract addresses:

```bash
export STABLE_SWAP_HOOK=0x... # From deployment output
export DSU_TOKEN=0x...        # From deployment output
export USDC_TOKEN=0x...       # From deployment output
export SWAP_ROUTER=0x...      # From deployment output
export POOL_MANAGER=0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A
```

### Step 3: Run Tests

Execute the test script:

```bash
forge script script/TestStableSwap.s.sol:TestStableSwap \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  -vvvv
```

## Contract Interactions

### Adding Liquidity

```solidity
// Approve tokens
dsu.approve(address(hook), amount0);
usdc.approve(address(hook), amount1);

// Add liquidity
hook.addLiquidity(poolKey, amount0, amount1);
```

### Executing Swaps

Swaps are executed through the Uniswap V4 swap router:

```solidity
IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
    zeroForOne: true, // DSU -> USDC
    amountSpecified: -1000e18, // 1000 DSU exact input
    sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
});

swapRouter.swap(poolKey, params, testSettings, "");
```

### Removing Liquidity

```solidity
hook.removeLiquidity(poolKey, liquidityAmount);
```

### View Functions

```solidity
// Get current reserves
(uint256 reserve0, uint256 reserve1) = hook.getReserves(currency0, currency1);

// Get virtual price (useful for monitoring pool health)
uint256 virtualPrice = hook.getVirtualPrice(currency0, currency1);
```

## Key Features

1. **Stable Swap Math**: Uses Curve's stable swap invariant with Newton's method
2. **Low Slippage**: Amplification coefficient A=1000 provides minimal slippage
3. **Hook Integration**: Full Uniswap V4 hook support with custom swap logic
4. **ERC6909 Claims**: Uses Uniswap V4's native token accounting

## Testing Different Scenarios

The test script includes:
- Small swaps (100 tokens) - minimal slippage
- Medium swaps (5,000 tokens) - low slippage
- Large swaps (20,000 tokens) - higher slippage
- Bidirectional swaps
- Liquidity addition/removal

## Troubleshooting

1. **Hook Permission Error**: Ensure the hook address has correct permission bits
2. **Insufficient Liquidity**: Add more liquidity before large swaps
3. **Gas Estimation Failed**: Check token approvals and balances

## Integration with Frontend

To integrate with a frontend:

1. Use the deployed contract addresses
2. Approve tokens for the swap router
3. Call swap functions through the PoolSwapTest contract
4. Monitor events from PoolManager

## Security Considerations

- This is a proof of concept implementation
- Audit before mainnet deployment
- Consider adding:
  - Access controls for liquidity management
  - Fee collection mechanisms
  - Emergency pause functionality
  - Slippage protection

## Next Steps

1. Add dynamic fee adjustment based on pool imbalance
2. Implement multi-asset pools (3+ tokens)
3. Add oracle price feeds for additional safety
4. Create a dedicated frontend interface
5. Implement governance for parameter updates