#!/bin/bash

# Script to find valid salts for StableSwap Hook deployment

set -e

echo "================================================"
echo "Finding Valid Salts for StableSwap Hook"
echo "================================================"

# Load environment variables
if [ -f .env.bsc ]; then
    source .env.bsc
else
    echo "Error: .env.bsc file not found!"
    exit 1
fi

if [ -z "$BSC_POOL_MANAGER" ]; then
    echo "Error: BSC_POOL_MANAGER not set in .env.bsc"
    exit 1
fi

echo ""
echo "Pool Manager: $BSC_POOL_MANAGER"
echo ""
echo "Mining for valid salts..."
echo "This may take a few minutes..."
echo ""

# Run the salt finder script
forge script script/FindValidHookSalt.s.sol:FindValidHookSalt \
    --rpc-url $BSC_RPC_URL \
    -vvv

echo ""
echo "Salt mining complete!"
echo "Copy one of the valid salts above and use it in your deployment."