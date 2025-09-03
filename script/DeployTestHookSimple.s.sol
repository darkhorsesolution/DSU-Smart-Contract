// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {LimitOrderHook} from "../src/hooks/testHook.sol";

contract DeployTestHookSimple is Script {
    // BSC Pool Manager
    address constant POOL_MANAGER = 0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF;
    
    // LimitOrderManager contract address
    address constant LIMIT_ORDER_MANAGER = 0x464eFbA4661cAB5FD10049f34477A2C50E965ae5;
    
    function run() external {
        // Load deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Deployer address:", deployer);
        console2.log("BSC Pool Manager:", POOL_MANAGER);
        console2.log("Limit Order Manager:", LIMIT_ORDER_MANAGER);
        
        // Admin will be deployer address
        address admin = deployer;
        
        console2.log("Admin:", admin);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the hook without CREATE2 first to test
        LimitOrderHook hook = new LimitOrderHook(
            IPoolManager(POOL_MANAGER),
            LIMIT_ORDER_MANAGER,
            admin
        );
        
        console2.log("=== DEPLOYMENT SUCCESSFUL ===");
        console2.log("Hook deployed at:", address(hook));
        console2.log("Hook address permissions (last 14 bits):", uint160(address(hook)) & 0x3FFF);
        
        vm.stopBroadcast();
    }
}