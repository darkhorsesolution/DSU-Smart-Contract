// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title CREATE2 Deployer for mining hook addresses
contract CREATE2Deployer {
    event ContractDeployed(address indexed deployed, bytes32 indexed salt);
    
    /// @notice Deploy contract using CREATE2
    function deploy(bytes32 salt, bytes memory bytecode) external payable returns (address deployed) {
        assembly {
            deployed := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(deployed != address(0), "CREATE2: deployment failed");
        emit ContractDeployed(deployed, salt);
    }
    
    /// @notice Compute CREATE2 address
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            bytecodeHash
        )))));
    }
}