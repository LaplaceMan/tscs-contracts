// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./EntityManager.sol";
import "../interfaces/IItemNFT.sol";

contract ItemManager is EntityManager {
    /**
     * @notice 记录Item详细信息
     */
    mapping(uint256 => DataTypes.ItemStruct) itemsNFT;
    /**
     * @notice 用户是否对Item评价过
     */
    mapping(address => mapping(uint256 => bool)) evaluated;
    /**
     * @notice 用户建议特定任务应该采纳的Item
     */
    mapping(address => mapping(uint256 => uint256)) adopted;

    /**
     * @notice 当DAO判定Item为恶意时，"删除"它
     * @param itemId 恶意Item的ID
     * @param state Item新的状态
     * Fn 1
     */
    function holdItemStateByDAO(
        uint256 itemId,
        DataTypes.ItemState state
    ) external auth {
        assert(state != DataTypes.ItemState.ADOPTED);
        _changeItemState(itemId, state);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 创建Item
     * @param maker Item制作者地址
     * @param vars Item信息
     * @return 相应Item ID
     * Fn 2
     */
    function _submitItem(
        address maker,
        DataTypes.ItemMetadata calldata vars
    ) internal returns (uint256) {
        address itemToken = IComponentGlobal(componentGlobal).itemToken();
        uint256 itemId = IItemNFT(itemToken).mintItemTokenByMurmes(maker, vars);
        itemsNFT[itemId].taskId = vars.taskId;
        itemsNFT[itemId].stateChangeTime = block.timestamp;
        return itemId;
    }

    /**
     * @notice 改变Item状态
     * @param itemId Item的ID
     * @param state 改变后的状态
     * Fn 3
     */
    function _changeItemState(
        uint256 itemId,
        DataTypes.ItemState state
    ) internal {
        itemsNFT[itemId].state = state;
        itemsNFT[itemId].stateChangeTime = block.timestamp;
        emit Events.ItemStateUpdate(itemId, state);
    }

    /**
     * @notice 审核Item
     * @param itemId Item的ID
     * @param attitude 审核结果
     * @param auditor 审核/检测员
     * Fn 4
     */
    function _auditItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude,
        address auditor
    ) internal {
        require(itemsNFT[itemId].state == DataTypes.ItemState.NORMAL, "I35");
        require(evaluated[auditor][itemId] == false, "I34");
        if (attitude == DataTypes.AuditAttitude.SUPPORT) {
            uint256 taskId = itemsNFT[itemId].taskId;
            require(adopted[auditor][taskId] == 0, "I30");
            itemsNFT[itemId].supporters.push(auditor);
            adopted[auditor][taskId] = itemId;
        } else {
            itemsNFT[itemId].opponents.push(auditor);
        }
        evaluated[auditor][itemId] = true;
    }

    // ***************** View Functions *****************
    function getItem(
        uint256 itemId
    ) external view returns (DataTypes.ItemStruct memory) {
        return itemsNFT[itemId];
    }

    function isEvaluated(
        address user,
        uint256 itemId
    ) external view returns (bool) {
        return evaluated[user][itemId];
    }
}
