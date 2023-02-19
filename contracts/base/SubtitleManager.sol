/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-06 20:23:26
 * @Description: 字幕代币化和管理, ERC721 标准实现（沿用了 OpenZeppelin 提供的模板）
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IST.sol";

contract SubtitleManager {
    /**
     * @notice ST 合约地址
     */
    address public subtitleToken;

    /**
     * @notice ST 版本管理合约
     */
    address public versionManagement;
    /**
     * @notice 每个字幕 ST 在生成时都会初始化相应的 Subtitle 结构
     * @param state 字幕当前状态, 0 为默认状态, 1 为被确认, 2 为被认定为恶意字幕
     * @param stateChangeTime 字幕状态改变时的时间戳, 用于利益相关者稳定币锁定期判断, 在申请未确认前, 指的是字幕上传时间
     * @param supporters 支持该字幕被采纳的观众（审核员）地址集合
     * @param dissenters 举报该字幕为恶意字幕的观众（审核员）地址集合
     */
    struct Subtitle {
        uint8 state;
        uint256 taskId;
        uint256 stateChangeTime;
        address[] supporters;
        address[] dissenters;
    }

    /**
     * @notice 与传统 ERC721 代币相比 每个 ST（Subtitle Token）都有相应的 Subtitle 结构记录字幕的详细信息, 因为观众评价（审核）机制的引入, ST 是动态的 NFT
     */
    mapping(uint256 => Subtitle) subtitleNFT;

    /**
     * @notice 限制每个用户只能对每个字幕评价一次, 用户区块链地址 => ST ID => 是否评价（true 为已参与评价）
     */
    mapping(address => mapping(uint256 => bool)) evaluated;
    /**
     * @notice 限制每个用户只能给每个申请下已上传字幕中的一个好评, 用户区块链地址 => apply ID => 支持的 ST ID
     */
    mapping(address => mapping(uint256 => uint256)) adopted;

    event SubtilteStateChange(uint256 subtitleId, uint8 state, uint256 taskId);
    event SubitlteGetEvaluation(
        uint256 subtitleId,
        address evaluator,
        uint8 attitude
    );

    /**
     * @notice 创建 ST, 内部功能
     * @param maker 字幕制作者区块链地址
     * @param taskId 字幕所属申请的 ID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹, 此处暂定为 Simhash
     * @return 字幕代币 ST（Subtitle Token） ID
     * label S1
     */
    function _createST(
        address maker,
        uint256 taskId,
        string memory cid,
        uint32 languageId,
        uint256 fingerprint
    ) internal returns (uint256) {
        uint256 id = IST(subtitleToken).mintST(
            maker,
            taskId,
            cid,
            languageId,
            fingerprint
        );
        subtitleNFT[id].taskId = taskId;
        subtitleNFT[id].stateChangeTime = block.timestamp;
        return id;
    }

    /**
     * @notice 更改字幕状态, 0 为无变化, 1 为被确认, 2 为被删除（即被认定为恶意字幕）, 内部功能
     * @param id ST（Subtitle Token） ID
     * @param state 新状态
     * label S2
     */
    function _changeST(uint256 id, uint8 state) internal {
        subtitleNFT[id].state = state;
        subtitleNFT[id].stateChangeTime = block.timestamp;
        emit SubtilteStateChange(id, state, subtitleNFT[id].taskId);
    }

    /**
     * @notice 评价字幕, 内部功能
     * @param subtitleId ST（Subtitle Token） ID
     * @param attitude 评价态度, 0 为支持（积极的）, 1 为反对（消极的）
     * @param evaluator 评价者（观众、审核员）区块链地址
     * label S3
     */
    function _evaluateST(
        uint256 subtitleId,
        uint8 attitude,
        address evaluator
    ) internal {
        require(subtitleNFT[subtitleId].state == 0, "S33");
        require(evaluated[evaluator][subtitleId] == false, "S34");
        if (attitude == 0) {
            require(
                adopted[evaluator][subtitleNFT[subtitleId].taskId] == 0,
                "S32"
            );
            subtitleNFT[subtitleId].supporters.push(evaluator);
            adopted[evaluator][subtitleNFT[subtitleId].taskId] = subtitleId;
        } else {
            subtitleNFT[subtitleId].dissenters.push(evaluator);
        }
        evaluated[evaluator][subtitleId] = true;
        emit SubitlteGetEvaluation(subtitleId, evaluator, attitude);
    }

    /**
     * @notice 获得字幕 ST 的基本信息
     * @param subtitleId 字幕 ID
     * @return 返回字幕状态（1 为确认，2 为被删除）、所属申请 ID、状态改变时间、支持者和反对者信息
     * label S4
     */
    function getSubtitleBaseInfo(uint256 subtitleId)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            address[] memory,
            address[] memory
        )
    {
        return (
            subtitleNFT[subtitleId].state,
            subtitleNFT[subtitleId].taskId,
            subtitleNFT[subtitleId].stateChangeTime,
            subtitleNFT[subtitleId].supporters,
            subtitleNFT[subtitleId].dissenters
        );
    }
}
