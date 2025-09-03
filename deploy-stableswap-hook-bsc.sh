#!/bin/bash

# StableSwap Hook Deployment Script for BSC
# This script deploys the StableSwap Hook using CREATE2 to ensure correct permission bits

set -e

echo "================================================"
echo "StableSwap Hook Deployment on BSC Mainnet"
echo "================================================"

# Load environment variables
if [ -f .env.bsc ]; then
    echo "Loading BSC environment variables..."
    source .env.bsc
else
    echo "Error: .env.bsc file not found!"
    echo "Please create .env.bsc with required configuration"
    exit 1
fi

# Check required environment variables
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: DEPLOYER_PRIVATE_KEY not set in .env.bsc"
    exit 1
fi

if [ -z "$BSC_POOL_MANAGER" ]; then
    echo "Error: BSC_POOL_MANAGER not set in .env.bsc"
    exit 1
fi

# Create deployments directory if it doesn't exist
mkdir -p deployments

echo ""
echo "Configuration:"
echo "- Network: BSC Mainnet"
echo "- RPC URL: $BSC_RPC_URL"
echo "- Pool Manager: $BSC_POOL_MANAGER"
echo "- Deployer: $(cast wallet address --private-key $DEPLOYER_PRIVATE_KEY)"
echo ""

# Check deployer balance
echo "Checking deployer balance..."
BALANCE=$(cast balance $(cast wallet address --private-key $DEPLOYER_PRIVATE_KEY) --rpc-url $BSC_RPC_URL)
echo "Deployer balance: $BALANCE wei"

# Convert balance to BNB for readability
BALANCE_BNB=$(echo "scale=6; $BALANCE / 1000000000000000000" | bc)
echo "Deployer balance: $BALANCE_BNB BNB"

# Check if balance is sufficient (at least 0.1 BNB recommended)
MIN_BALANCE=100000000000000000  # 0.1 BNB in wei
if [ "$BALANCE" -lt "$MIN_BALANCE" ]; then
    echo "Warning: Deployer balance is low. Recommended minimum: 0.1 BNB"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Starting deployment..."
echo ""

# Run the deployment script
forge script script/DeployStableSwapHookBSC.s.sol:DeployStableSwapHookBSC \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --verify \
    --verifier-url $ETHERSCAN_API_URL \
    --etherscan-api-key $BSCSCAN_API_KEY \
    -vvvv

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "Deployment Successful!"
    echo "================================================"
    echo ""
    echo "Check deployments/bsc-stableswap-hook.txt for deployment details"
    echo ""
    
    # Display deployment info if file exists
    if [ -f deployments/bsc-stableswap-hook.txt ]; then
        echo "Deployment Details:"
        cat deployments/bsc-stableswap-hook.txt
    fi
    
    echo ""
    echo "Next Steps:"
    echo "1. Update .env.bsc with the deployed hook address"
    echo "2. Initialize pools using the deployed hook"
    echo "3. Add liquidity to the pools"
    echo ""
else
    echo ""
    echo "Deployment failed! Check the error messages above."
    exit 1
fi