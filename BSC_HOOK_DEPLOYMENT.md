# StableSwap Hook Deployment on BSC

This guide explains how to deploy the StableSwap Hook on BSC Mainnet using CREATE2 to ensure the hook address has the correct permission bits as required by Uniswap V4.

## Prerequisites

1. **Node.js and Foundry** installed
2. **BNB for gas fees** (at least 0.1 BNB recommended)
3. **BSCScan API key** for contract verification
4. **Pool Manager address** deployed on BSC

## Understanding Hook Permissions

Uniswap V4 hooks require specific permission bits encoded in the contract address. The StableSwap Hook needs:

- `BEFORE_ADD_LIQUIDITY_FLAG` - To prevent V4 liquidity management
- `BEFORE_SWAP_FLAG` - To handle custom curve swaps
- `BEFORE_SWAP_RETURNS_DELTA_FLAG` - To enable custom swap curves

These permissions are encoded in the last 14 bits of the hook address.

## Setup

### 1. Configure Environment

Create or update `.env.bsc` with your configuration:

```bash
# BSC Mainnet Configuration
DEPLOYER_PRIVATE_KEY=your_private_key_here

# RPC URLs
BSC_RPC_URL=https://bsc-dataseed.binance.org/

# BSCScan API Key
BSCSCAN_API_KEY=your_bscscan_api_key_here

# Pool Manager Address
BSC_POOL_MANAGER=0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF
```

### 2. Install Dependencies

```bash
forge install
```

## Deployment Process

### Step 1: Find Valid Salt (Optional)

Before deployment, you can find valid salts that will produce addresses with correct permission bits:

```bash
./find-hook-salt.sh
```

This will output several valid salts you can use. The deployment script will also automatically find a valid salt if needed.

### Step 2: Deploy the Hook

Run the deployment script:

```bash
./deploy-stableswap-hook-bsc.sh
```

The script will:
1. Check deployer balance
2. Mine for a valid salt (if not provided)
3. Deploy the hook using CREATE2
4. Verify the contract on BSCScan
5. Save deployment details to `deployments/bsc-stableswap-hook.txt`

## How CREATE2 Deployment Works

CREATE2 allows us to deploy contracts to deterministic addresses based on:
- Deployer address
- Salt (32-byte value)
- Contract bytecode

The deployment script:
1. Calculates the bytecode hash of the StableSwap Hook
2. Iterates through different salt values
3. Computes the CREATE2 address for each salt
4. Checks if the address has correct permission bits
5. Deploys using the first valid salt found

## Verification

After deployment, verify that:

1. **Address has correct permissions**: The last 14 bits of the address should match the required permission flags
2. **Contract is verified on BSCScan**: Check the contract on BSCScan
3. **Hook functions correctly**: Test swaps and liquidity operations

## Testing the Deployed Hook

After deployment, test the hook:

```solidity
// Initialize a pool with the hook
PoolKey memory key = PoolKey({
    currency0: Currency.wrap(token0),
    currency1: Currency.wrap(token1),
    fee: 3000,
    tickSpacing: 60,
    hooks: IHooks(deployedHookAddress)
});

poolManager.initialize(key, SQRT_PRICE_1_1);
```

## Troubleshooting

### "No valid salt found"
- Increase `maxIterations` in the deployment script
- Try different starting salts
- Ensure the permission flags are correct

### "Deployed address mismatch"
- Verify the bytecode matches exactly
- Check that constructor arguments are correct
- Ensure using the correct CREATE2 deployer address

### Gas estimation errors
- Increase gas limit in `.env.bsc`
- Ensure sufficient BNB balance
- Try a different RPC endpoint

## Contract Addresses

- **CREATE2 Deployer (BSC)**: `0x4e59b44847b379578588920cA78FBf26c0b4956C`
- **Pool Manager**: Update in `.env.bsc` after deployment
- **StableSwap Hook**: Will be displayed after deployment

## Security Considerations

1. **Private Key Security**: Never commit `.env.bsc` to version control
2. **Verify Contracts**: Always verify on BSCScan for transparency
3. **Test Thoroughly**: Test all hook functions before production use
4. **Audit**: Consider professional audit for production deployments

## Next Steps

After successful deployment:

1. Update `.env.bsc` with the deployed hook address
2. Deploy token contracts if needed
3. Initialize pools using the hook
4. Add initial liquidity
5. Test swap operations

## References

- [Uniswap V4 Hook Documentation](https://docs.uniswap.org/contracts/v4/guides/hooks)
- [CREATE2 Opcode Documentation](https://eips.ethereum.org/EIPS/eip-1014)
- [BSC Documentation](https://docs.bnbchain.org/)