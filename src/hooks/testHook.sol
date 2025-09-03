// SPDX-License-Identifier: BSL
pragma solidity ^0.8.24;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {TransientSlot} from "../lib/TransientSlot.sol";
import {ILimitOrderManager} from "../lib/ILimitOrderManager.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SwapParams} from "v4-core/src/types/PoolOperation.sol";

contract LimitOrderHook is BaseHook, AccessControl {
    using PoolIdLibrary for PoolKey;
    using TransientSlot for *;

    bytes32 private constant PREVIOUS_TICK_SLOT = keccak256("xyz.hooks.limitorder.previous-tick");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    
    ILimitOrderManager public immutable limitOrderManager;

    // Events
    event DynamicLPFeeUpdated(PoolId indexed poolId, uint24 newFee);

    constructor(
        IPoolManager _poolManager, 
        address _limitOrderManager, 
        address _admin
    ) BaseHook(_poolManager) {
        require(_limitOrderManager != address(0));
        limitOrderManager = ILimitOrderManager(_limitOrderManager);
        
        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(FEE_MANAGER_ROLE, _admin);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,  
            afterInitialize: false,   
            beforeAddLiquidity: false,  
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false, 
            afterRemoveLiquidity: false,
            beforeSwap: true,  
            afterSwap: true,   
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false, 
            afterSwapReturnDelta: false,  
            afterAddLiquidityReturnDelta: false, 
            afterRemoveLiquidityReturnDelta: false
        });
    }


    function _beforeSwap(
        address,
        PoolKey calldata key, 
        SwapParams calldata,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function updateDynamicLPFee(PoolKey calldata key, uint24 newFee) external onlyRole(FEE_MANAGER_ROLE) {
        require(newFee <= 50000, "Fee exceeds maximum of 5%");
        poolManager.updateDynamicLPFee(key, newFee);
        emit DynamicLPFeeUpdated(key.toId(), newFee);
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        return (BaseHook.afterSwap.selector, 0);
    }
}