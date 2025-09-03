// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LimitOrderHook} from "../src/hooks/testHook.sol";
import {CREATE2Factory} from "../src/lib/CREATE2Factory.sol";

contract DeployTestHookWithFactory is Script {
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
        
        // Get required permissions for the hook
        uint160 permissions = getHookPermissions();
        console2.log("Required permissions:", permissions);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy CREATE2 factory first
        CREATE2Factory factory = new CREATE2Factory();
        console2.log("CREATE2Factory deployed at:", address(factory));
        
        // Get creation code with constructor args
        bytes memory creationCode = abi.encodePacked(
            type(LimitOrderHook).creationCode,
            abi.encode(IPoolManager(POOL_MANAGER), LIMIT_ORDER_MANAGER, admin)
        );
        
        bytes32 creationCodeHash = keccak256(creationCode);
        
        // Find a valid salt for CREATE2 deployment
        (address expectedHookAddress, bytes32 salt) = findSalt(
            address(factory),
            permissions,
            creationCodeHash
        );
        
        console2.log("Expected Hook Address:", expectedHookAddress);
        console2.log("Salt:", uint256(salt));
        
        // Deploy the hook using CREATE2Factory
        address deployedHook = factory.deploy(salt, creationCode);
        
        console2.log("=== DEPLOYMENT SUCCESSFUL ===");
        console2.log("Hook deployed at:", deployedHook);
        console2.log("Expected vs Deployed match:", deployedHook == expectedHookAddress);
        
        // Verify the permissions
        verifyPermissions(deployedHook, permissions);
        
        vm.stopBroadcast();
    }
    
    function getHookPermissions() internal pure returns (uint160) {
        // The testHook only uses beforeSwap and afterSwap
        return uint160(
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );
    }
    
    function findSalt(
        address deployer,
        uint160 permissions,
        bytes32 creationCodeHash
    ) internal pure returns (address hookAddress, bytes32 salt) {
        // Try to find a valid salt
        for (uint256 i = 0; i < 100000; i++) {
            salt = bytes32(i);
            hookAddress = computeAddress(deployer, salt, creationCodeHash);
            
            if (isValidHookAddress(hookAddress, permissions)) {
                console2.log("Found valid salt at iteration:", i);
                return (hookAddress, salt);
            }
        }
        
        revert("Could not find valid salt for hook deployment");
    }
    
    function isValidHookAddress(address hookAddress, uint160 permissions) internal pure returns (bool) {
        // Extract the permission bits from the address (bottom 14 bits)
        uint160 addressBits = uint160(hookAddress) & 0x3FFF;
        
        // Check if all required bits are set
        return (addressBits & permissions) == permissions;
    }
    
    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes32 creationCodeHash
    ) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            creationCodeHash
        )))));
    }
    
    function verifyPermissions(address hookAddress, uint160 expectedPermissions) internal pure {
        uint160 addressBits = uint160(hookAddress) & 0x3FFF;
        
        console2.log("Hook address bits:", addressBits);
        console2.log("Expected permissions:", expectedPermissions);
        
        if ((addressBits & expectedPermissions) != expectedPermissions) {
            revert("Hook address does not have correct permission bits");
        }
        
        console2.log("Hook permissions verified successfully");
    }
}