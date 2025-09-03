#!/bin/bash

# Initialize Pool with StableSwap Hook on BSC

set -e

echo "================================================"
echo "Pool Initialization on BSC Mainnet"
echo "================================================"

# Load environment variables
source .env.bsc

echo ""
echo "Configuration:"
echo "- Pool Manager: 0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF"
echo "- StableSwap Hook: 0x2de0BF594c46C196D5a01A3e14DDAc15d4E73786"
echo "- Token 0: 0x7Cd3CaDEba6CceD7a5a85673187103E0345F8dc8"
echo "- Token 1: 0xe19c6404BACfAae1F666085860dfe0150A633cFd"
echo ""

# Initialize the pool
echo "Step 1: Initializing pool..."
echo "--------------------------------"
DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY \
forge script script/InitializePoolBSC.s.sol:InitializePoolBSC \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --legacy \
    --slow \
    -vvv

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Pool initialized successfully!"
    echo ""
    
    read -p "Do you want to add liquidity now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Step 2: Adding liquidity..."
        echo "--------------------------------"
        DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY \
        forge script script/AddLiquidityBSC.s.sol:AddLiquidityBSC \
            --rpc-url $BSC_RPC_URL \
            --broadcast \
            --legacy \
            --slow \
            -vvv
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ Liquidity added successfully!"
            echo ""
            echo "================================================"
            echo "Pool Setup Complete!"
            echo "================================================"
            echo ""
            echo "Your pool is now ready for trading!"
            echo "Pool Details:"
            echo "- Token Pair: 0x7Cd3CaDEba6CceD7a5a85673187103E0345F8dc8 / 0xe19c6404BACfAae1F666085860dfe0150A633cFd"
            echo "- Fee: 0.01%"
            echo "- Hook: StableSwap (1:1 trading)"
        else
            echo "❌ Failed to add liquidity"
            exit 1
        fi
    fi
else
    echo "❌ Failed to initialize pool"
    exit 1
fi