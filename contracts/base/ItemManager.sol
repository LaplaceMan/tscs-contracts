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
     * @notice 与传统 ERC721 代币相比 每个 ST（Subtitle Token）都有相应的 Subtitle 结构记录字幕的详细信息, 因为观众评价（审核）机制的引入, ST 是动态的 NFT
     */
    mapping(uint256 => DataTypes.ItemStruct) itemsNFT;
    /**
     * @notice 限制每个用户只能对每个字幕评价一次, 用户区块链地址 => ST ID => 是否评价（true 为已参与评价）
     */
    mapping(address => mapping(uint256 => bool)) evaluated;
    /**
     * @notice 限制每个用户只能给每个申请下已上传字幕中的一个好评, 用户区块链地址 => apply ID => 支持的 ST ID
     */
    mapping(address => mapping(uint256 => uint256)) adopted;

    event ItemStateChange(
        uint256 itemId,
        DataTypes.ItemState state,
        uint256 taskId
    );
    event ItemGetEvaluation(
        uint256 itemId,
        address evaluator,
        DataTypes.AuditAttitude attitude
    );

    /**
     * @notice 当 DAO 判定字幕为恶意时，删除字幕，由于加密思想，我们并没有在链上删掉ST的信息，而是在本系统内作标记，将不再认可它
     * @param id 恶意ST ID
     * label S6
     */
    function holdSubtitleStateByDAO(uint256 id, DataTypes.ItemState state)
        external
        auth
    {
        assert(state != DataTypes.ItemState.ADOPTED);
        _changeItemState(id, state);
    }

    function _createItem(
        address maker,
        uint256 taskId,
        string memory cid,
        uint256 requireId,
        uint256 fingerprint
    ) internal returns (uint256) {
        address itemToken = IComponentGlobal(componentGlobal).itemToken();
        uint256 id = IItemNFT(itemToken).mintItemToken(
            maker,
            taskId,
            cid,
            requireId,
            fingerprint
        );
        itemsNFT[id].taskId = taskId;
        itemsNFT[id].stateChangeTime = block.timestamp;
        return id;
    }

    function _changeItemState(uint256 id, DataTypes.ItemState state) internal {
        itemsNFT[id].state = state;
        itemsNFT[id].stateChangeTime = block.timestamp;
        emit ItemStateChange(id, state, itemsNFT[id].taskId);
    }

    function _evaluateItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude,
        address evaluator
    ) internal {
        require(itemsNFT[itemId].state == DataTypes.ItemState.NORMAL, "S33");
        require(evaluated[evaluator][itemId] == false, "S34");
        if (attitude == DataTypes.AuditAttitude.SUPPORT) {
            uint256 taskId = itemsNFT[itemId].taskId;
            require(adopted[evaluator][taskId] == 0, "S32");
            itemsNFT[itemId].supporters.push(evaluator);
            adopted[evaluator][taskId] = itemId;
        } else {
            itemsNFT[itemId].dissenters.push(evaluator);
        }
        evaluated[evaluator][itemId] = true;
        emit ItemGetEvaluation(itemId, evaluator, attitude);
    }

    function getItem(uint256 itemId)
        external
        view
        returns (DataTypes.ItemStruct memory item)
    {
        return itemsNFT[itemId];
    }
}
