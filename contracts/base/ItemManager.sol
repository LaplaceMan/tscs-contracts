/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-06 20:23:26
 * @Description: 字幕代币化和管理, ERC721 标准实现（沿用了 OpenZeppelin 提供的模板）
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
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
     * @param itemId 恶意Item ID
     * Fn 1
     */
    function holdSubtitleStateByDAO(uint256 itemId, DataTypes.ItemState state)
        external
        auth
    {
        assert(state != DataTypes.ItemState.ADOPTED);
        _changeItemState(itemId, state);
    }

    /**
     * @notice 创建Item
     * @param maker Item制作者地址
     * @param vars Item信息
     * @return 相应Item ID
     * Fn 2
     */
    function _createItem(address maker, DataTypes.SubmitItemData calldata vars)
        internal
        returns (uint256)
    {
        address itemToken = IComponentGlobal(componentGlobal).itemToken();
        uint256 itemId = IItemNFT(itemToken).mintItemToken(maker, vars);
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
    function _changeItemState(uint256 itemId, DataTypes.ItemState state)
        internal
    {
        itemsNFT[itemId].state = state;
        itemsNFT[itemId].stateChangeTime = block.timestamp;
    }

    function _evaluateItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude,
        address evaluator
    ) internal {
        require(itemsNFT[itemId].state == DataTypes.ItemState.NORMAL, "I35");
        require(evaluated[evaluator][itemId] == false, "I34");
        if (attitude == DataTypes.AuditAttitude.SUPPORT) {
            uint256 taskId = itemsNFT[itemId].taskId;
            require(adopted[evaluator][taskId] == 0, "I30");
            itemsNFT[itemId].supporters.push(evaluator);
            adopted[evaluator][taskId] = itemId;
        } else {
            itemsNFT[itemId].opponents.push(evaluator);
        }
        evaluated[evaluator][itemId] = true;
    }

    // ***************** View Functions *****************
    function getItem(uint256 itemId)
        external
        view
        returns (DataTypes.ItemStruct memory item)
    {
        return itemsNFT[itemId];
    }
}
