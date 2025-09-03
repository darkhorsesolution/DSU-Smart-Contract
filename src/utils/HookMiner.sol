// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @title HookMiner - Library for mining hook addresses
/// @notice Helps find CREATE2 salts for deploying hooks with correct permission bits
library HookMiner {
    /// @notice Find a salt that produces a hook address with correct permissions
    /// @param deployer The address that will deploy the hook
    /// @param permissions The required hook permissions
    /// @param creationCodeHash The keccak256 hash of the hook's creation code
    /// @param startSalt Starting salt for search
    /// @param maxIterations Maximum iterations to search
    /// @return hookAddress The address that will be deployed
    /// @return salt The salt to use for deployment
    function find(
        address deployer,
        uint160 permissions,
        bytes32 creationCodeHash,
        bytes32 startSalt,
        uint256 maxIterations
    ) internal pure returns (address hookAddress, bytes32 salt) {
        for (uint256 i = 0; i < maxIterations; i++) {
            salt = bytes32(uint256(startSalt) + i);
            hookAddress = computeAddress(deployer, salt, creationCodeHash);
            
            if (isValidHookAddress(hookAddress, permissions)) {
                return (hookAddress, salt);
            }
        }
        revert("HookMiner: No valid salt found");
    }
    
    /// @notice Check if an address has the correct permission bits
    function isValidHookAddress(address hookAddress, uint160 permissions) internal pure returns (bool) {
        // Get the required permission bits
        uint160 requiredBits = permissions;
        
        // Extract the permission bits from the address (bottom 14 bits)
        uint160 addressBits = uint160(hookAddress) & 0x3FFF; // 0x3FFF = 14 bits mask
        
        // Check if all required bits are set
        return (addressBits & requiredBits) == requiredBits;
    }
    
    /// @notice Compute CREATE2 address
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
    
    /// @notice Get the required permissions for a stable swap hook
    function getStableSwapHookPermissions() internal pure returns (uint160) {
        return uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );
    }
}