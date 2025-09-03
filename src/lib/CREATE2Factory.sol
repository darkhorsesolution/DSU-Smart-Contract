// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CREATE2Factory {
    event ContractDeployed(address indexed deployed, bytes32 indexed salt, address indexed deployer);
    
    function deploy(bytes32 salt, bytes calldata bytecode) external returns (address deployed) {
        assembly {
            deployed := create2(0, add(bytecode.offset, 0x20), bytecode.length, salt)
            
            if iszero(extcodesize(deployed)) {
                revert(0, 0)
            }
        }
        
        emit ContractDeployed(deployed, salt, msg.sender);
    }
    
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) external pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            bytecodeHash
        )))));
    }
}