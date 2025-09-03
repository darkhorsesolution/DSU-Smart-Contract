#!/bin/bash

# StableSwap Hook CREATE2 Deployment Script for BSC
# This script deploys the StableSwap Hook using CREATE2 with proper salt mining

set -e

echo "================================================"
echo "StableSwap Hook CREATE2 Deployment on BSC"
echo "================================================"

# Load environment variables
source .env.bsc

# Run the deployment with CREATE2
DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY \
BSC_POOL_MANAGER=$BSC_POOL_MANAGER \
forge script script/DeployStableSwapHookBSC.s.sol:DeployStableSwapHookBSC \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --slow \
    --legacy \
    -vvv

echo ""
echo "Deployment complete!"