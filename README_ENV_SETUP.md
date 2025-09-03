# Environment Setup for StableSwap Deployment

## Using the Existing .env File

The project already has a comprehensive `.env` file with all necessary configurations. The StableSwap deployment scripts are configured to use these existing environment variables.

## Key Environment Variables Used

1. **Deployment Key**: `DEPLOYER_PRIVATE_KEY`
2. **RPC URL**: `SEPOLIA_RPC_URL` 
3. **Pool Manager**: `POOL_MANAGER` (already set to Sepolia address)
4. **Etherscan API**: `ETHERSCAN_API_KEY`

## After Deployment

After running the deployment script, you need to add these addresses to your `.env` file:

```bash
# Deployed StableSwap Contracts (add after deployment)
STABLE_SWAP_HOOK=0x...    # From deployment output
DSU_TOKEN=0x...           # Mock DSU address
USDC_TOKEN=0x...          # Mock USDC address  
SWAP_ROUTER=0x...         # PoolSwapTest address
```

## Deployment Steps

1. Your `.env` file is already configured with the necessary variables
2. Run: `./deploy-stable-swap.sh`
3. Copy the deployed addresses from the output
4. Add them to your `.env` file
5. Run: `./test-stable-swap.sh`

## Note on Pool Manager

The script uses the `POOL_MANAGER` address from your `.env` file:
- Current value: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`

This is the official Uniswap V4 Pool Manager on Sepolia. Make sure this address is correct for your deployment target.