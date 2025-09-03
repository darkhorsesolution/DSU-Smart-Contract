#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deploying Test Hook (LimitOrderHook) on BSC  ${NC}"
echo -e "${GREEN}========================================${NC}"

# Load environment variables
if [ -f .env.bsc ]; then
    source .env.bsc
    echo -e "${GREEN}✓ Loaded BSC environment variables${NC}"
else
    echo -e "${RED}✗ .env.bsc file not found${NC}"
    exit 1
fi

# Export required variables
export DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY
export BSC_POOL_MANAGER=$BSC_POOL_MANAGER

echo -e "\n${YELLOW}Configuration:${NC}"
echo "  Network: BSC Mainnet"
echo "  RPC URL: $BSC_RPC_URL"
echo "  Pool Manager: $BSC_POOL_MANAGER"

# Build the contracts
echo -e "\n${YELLOW}Building contracts...${NC}"
forge build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Contracts built successfully${NC}"

# Deploy the hook
echo -e "\n${YELLOW}Deploying Test Hook with permission-matched address...${NC}"
echo -e "${YELLOW}This will find a CREATE2 salt for the correct permission bits...${NC}"

forge script script/DeployTestHookFinal.s.sol:DeployTestHookFinal \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --legacy \
    --slow \
    -vvv

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  DEPLOYMENT SUCCESSFUL!  ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Save the deployed hook address"
    echo "2. Verify the contract on BSCScan if needed"
    echo "3. Deploy or connect the ILimitOrderManager contract"
    echo "4. Test the hook with a swap transaction"
else
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}  DEPLOYMENT FAILED  ${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Check the error messages above for details${NC}"
    exit 1
fi