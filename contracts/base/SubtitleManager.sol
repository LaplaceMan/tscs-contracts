/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-06 20:23:26
 * @Description: 字幕代币化和管理, ERC721 标准实现（沿用了 OpenZeppelin 提供的模板）
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC721/ERC721.sol";

contract SubtitleManager is ERC721 {
    /**
     * @notice ERC721 代币 ID 顺位
     */
    uint256 private _tokenIdTracker;

    /**
     * @notice 每个字幕 ST 在生成时都会初始化相应的 Subtitle 结构
     * @param applyId 字幕所属申请的 ID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹信息, 此处暂定为 Simhash
     * @param state 字幕当前状态, 0 为默认状态, 1 为被确认, 2 为被认定为恶意字幕
     * @param stateChangeTime 字幕状态改变时的时间戳, 用于利益相关者稳定币锁定期判断
     * @param supporters 支持该字幕被采纳的观众（审核员）地址集合
     * @param dissenter 举报该字幕为恶意字幕的观众（审核员）地址集合
     */
    struct Subtitle {
        uint256 applyId;
        uint16 languageId;
        uint256 fingerprint;
        uint8 state;
        uint256 stateChangeTime;
        address[] supporters;
        address[] dissenter;
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
     * @notice 创建 ST, 内部功能
     * @param maker 字幕制作者区块链地址
     * @param applyId 字幕所属申请的 ID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹, 此处暂定为 Simhash
     * @return 字幕代币 ST（Subtitle Token） ID
     */
    function _createST(
        address maker,
        uint256 applyId,
        uint16 languageId,
        uint256 fingerprint
    ) internal returns (uint256) {
        _tokenIdTracker++;
        _mint(maker, _tokenIdTracker);
        subtitleNFT[_tokenIdTracker].applyId = applyId;
        subtitleNFT[_tokenIdTracker].languageId = languageId;
        subtitleNFT[_tokenIdTracker].fingerprint = fingerprint;
        return _tokenIdTracker;
    }

    /**
     * @notice 更改字幕状态, 0 为无变化, 1 为被确认, 2 为被删除（即被认定为恶意字幕）, 内部功能
     * @param id ST（Subtitle Token） ID
     * @param state 新状态
     */
    function _changeST(uint256 id, uint8 state) internal {
        subtitleNFT[id].state = state;
        subtitleNFT[id].stateChangeTime = block.timestamp;
    }

    /**
     * @notice 评价字幕, 内部功能
     * @param subtitleId ST（Subtitle Token） ID
     * @param attitude 评价态度, 0 为支持（积极的）, 1 为反对（消极的）
     * @param evaluator 评价者（观众、审核员）区块链地址
     */
    function _evaluateST(
        uint256 subtitleId,
        uint8 attitude,
        address evaluator
    ) internal {
        require(subtitleNFT[subtitleId].state == 0, "Treated");
        require(evaluated[evaluator][subtitleId] == false, "Evaluated");
        if (attitude == 0) {
            subtitleNFT[subtitleId].supporters.push(evaluator);
        } else {
            subtitleNFT[subtitleId].dissenter.push(evaluator);
        }
        evaluated[evaluator][subtitleId] = true;
    }

    /**
     * @notice 获得 ST 基本信息
     * @param subtitleId 欲查询 ST（Subtitle Token） ID
     * @return 字幕代币 ST 所属申请的ID、所属语种的ID、指纹、当前状态、状态改变时间
     */
    function getSTBaseInfo(uint256 subtitleId)
        external
        view
        returns (
            uint256,
            uint16,
            uint256,
            uint8,
            uint256
        )
    {
        return (
            subtitleNFT[subtitleId].applyId,
            subtitleNFT[subtitleId].languageId,
            subtitleNFT[subtitleId].fingerprint,
            subtitleNFT[subtitleId].state,
            subtitleNFT[subtitleId].stateChangeTime
        );
    }
}
