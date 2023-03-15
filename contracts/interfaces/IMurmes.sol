// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IMurmes {
    // ***** Ownable *****
    function isOperator(address operator) external view returns (bool);

    function owner() external view returns (address);

    function multiSig() external view returns (address);

    // ***** EntityManager *****
    function componentGlobal() external view returns (address);

    function moduleGlobal() external view returns (address);

    function getUserBaseData(
        address user
    ) external view returns (uint256, int256);

    function getUserLockReward(
        address user,
        address platform,
        uint256 day
    ) external view returns (uint256);

    function gutUserGuard(address user) external view returns (address);

    function requiresNoteById(
        uint256 requireId
    ) external view returns (string memory);

    function requiresIdByNote(
        string memory requireNote
    ) external view returns (uint256);

    function updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) external;

    // ***** ItemManager *****
    function itemsNFT(
        uint256 itemId
    ) external view returns (DataTypes.ItemStruct memory);

    function holdItemStateByDAO(
        uint256 itemId,
        DataTypes.ItemState state
    ) external;

    // ***** TaskManager *****
    function totalTasks() external view returns (uint256);

    function tasks(
        uint256 taskId
    ) external view returns (DataTypes.TaskStruct memory);

    function getPlatformAddressByTaskId(
        uint256 taskId
    ) external view returns (address);

    function getTaskPaymentModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory);

    function getTaskItemsState(
        uint256 taskId
    ) external view returns (uint256, uint256, uint256);

    function updateTask(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) external;

    function cancelTask(uint256 taskId) external;

    function resetTask(uint256 taskId, uint256 amount) external;

    // ***** Murmes *****
    function preDivideBySettlementModule(
        address platform,
        address to,
        uint256 amount
    ) external;

    function preDivideBatchBySettlementModule(
        address platform,
        address[] memory to,
        uint256 amount
    ) external;

    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address user
    ) external;

    function getItemAuditData(
        uint256 itemId
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function getItemCustomModuleOfTask(
        uint256 itemId
    ) external view returns (address, address, address);

    function postTask(
        DataTypes.PostTaskData calldata vars
    ) external returns (uint256);

    function updateItemRevenue(uint256 taskId, uint256 counts) external;
}
