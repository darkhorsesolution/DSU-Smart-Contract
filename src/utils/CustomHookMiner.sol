// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Hooks} from "v4-core/src/libraries/Hooks.sol";

/// @title CustomHookMiner
/// @notice Optimized hook miner for BSC deployment
library CustomHookMiner {
    uint160 constant FLAG_MASK = Hooks.ALL_HOOK_MASK;
    uint256 constant MAX_LOOP = 100_000; // Increase search space
    
    function find(address deployer, uint160 flags, bytes memory creationCode, bytes memory constructorArgs)
        internal
        pure
        returns (address, bytes32)
    {
        flags = flags & FLAG_MASK;
        bytes memory creationCodeWithArgs = abi.encodePacked(creationCode, constructorArgs);
        
        address hookAddress;
        bytes32 initCodeHash = keccak256(creationCodeWithArgs);
        
        for (uint256 salt; salt < MAX_LOOP; salt++) {
            // Compute CREATE2 address efficiently
            bytes32 hash = keccak256(abi.encodePacked(
                bytes1(0xff),
                deployer,
                bytes32(salt),
                initCodeHash
            ));
            
            hookAddress = address(uint160(uint256(hash)));
            
            // Check if address has the desired flags
            if (uint160(hookAddress) & FLAG_MASK == flags) {
                return (hookAddress, bytes32(salt));
            }
        }
        revert("CustomHookMiner: could not find salt");
    }
}