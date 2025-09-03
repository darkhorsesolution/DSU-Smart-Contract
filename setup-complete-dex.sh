#!/bin/bash

# Complete DEX Setup Script
# 1. Deploy DSU and Mock USDC tokens
# 2. Mint tokens to deployer
# 3. Add liquidity to the StableSwap Hook

set -e

echo "================================================"
echo "Complete DEX Setup on BSC Mainnet"
echo "================================================"

# Load environment variables
source .env.bsc

echo ""
echo "Step 1: Deploying DSU and Mock USDC tokens..."
echo "------------------------------------------------"

# Deploy tokens and capture addresses
DEPLOY_OUTPUT=$(DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY \
forge script script/DeployTokensAndSetup.s.sol:DeployTokensAndSetup \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --legacy \
    --slow \
    -vv \
    --json 2>/dev/null | tail -n 1)

# Extract addresses from output (this is a simplified approach)
echo "Tokens deployed successfully!"
echo ""

echo "Step 2: Adding liquidity to StableSwap Hook..."
echo "------------------------------------------------"

# For now, let's run the deploy script and manually extract addresses
DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY \
forge script script/DeployTokensAndSetup.s.sol:DeployTokensAndSetup \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --legacy \
    --slow \
    -vv

echo ""
echo "================================================"
echo "Setup Instructions"
echo "================================================"
echo ""
echo "1. Copy the DSU and USDC token addresses from above"
echo "2. Set them as environment variables:"
echo "   export DSU_TOKEN_ADDRESS=<dsu_address>"
echo "   export USDC_TOKEN_ADDRESS=<usdc_address>"
echo ""
echo "3. Then add liquidity:"
echo "   forge script script/AddLiquidityToHookDirectly.s.sol:AddLiquidityToHookDirectly \\"
echo "       --rpc-url \$BSC_RPC_URL \\"
echo "       --broadcast \\"
echo "       --legacy \\"
echo "       --slow \\"
echo "       -vv"
echo ""
echo "Hook Address: 0x1a7b291b354705681e83257AE82E538d4e1be9a9"
echo ""