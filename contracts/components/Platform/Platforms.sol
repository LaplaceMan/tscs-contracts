/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-05 19:48:53
 * @Description: 管理 Platform, 包括添加和修改相关参数
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./VideoManager.sol";
import "../../interfaces/IVT.sol";
import "../../interfaces/IMurmes.sol";

contract Platforms is VideoManager {
    /**
     * @notice 已加入的 Platform 总数
     */
    address public Murmes;
    /**
     * @notice 操作员地址, 有权修改该策略中的关键参数
     */
    address public opeator;
    /**
     * @notice 已加入的 Platform 总数
     */
    uint256 public totalPlatforms;
    /**
     * @notice Platform 地址与相应结构体的映射
     */
    mapping(address => Platform) platforms;

    event SystemChangeOpeator(address newOpeator);

    /**
     * @notice 记录每个 Platform 的基本信息
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rateCountsToProfit 播放量与稳定币汇率, 最大为 65535（/65535）
     * @param rateAuditorDivide 审核员（字幕支持者）分成比例, 最大为 65535（/65535）
     */
    struct Platform {
        string name;
        string symbol;
        uint256 platformId;
        uint16 rateCountsToProfit;
        uint16 rateAuditorDivide;
    }

    event PlatformJoin(
        address platform,
        uint256 id,
        string name,
        string symbol,
        uint16 rate1,
        uint16 rate2
    );
    event PlatformSetRate(address platform, uint16 rate1, uint16 rate2);

    /**
     * @notice 仅能由 opeator 调用
     */
    modifier onlyOwner() {
        require(msg.sender == opeator, "ER5");
        _;
    }
    /**
     * @notice 仅能由 Murmes 调用
     */
    modifier auth() {
        require(msg.sender == Murmes, "ER5");
        _;
    }

    constructor(address op, address murmes) {
        Murmes = murmes;
        opeator = op;
        // 当结算类型为一次性结算时, 默认字幕支持者分成 1/100
        platforms[murmes].rateAuditorDivide = 655;
        platforms[murmes].name = "Default";
        platforms[murmes].symbol = "Default";
        // Default 索引为 0，但包括在总数内
        totalPlatforms += 1;
        emit PlatformJoin(murmes, 0, "Default", "Default", 0, 655);
    }

    /**
     * @notice 由 Murmes 管理员操作, 添加新 Platform 生态
     * @param platfrom Platform区块链地址,
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rate1 rateCountsToProfit 值必须大于0
     * @param rate2 rateAuditorDivide 值必须大于0
     */
    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external onlyOwner {
        require(platforms[platfrom].rateCountsToProfit == 0, "ER0");
        require(rate1 > 0 && rate2 > 0, "ER1");
        platforms[platfrom] = (
            Platform({
                name: name,
                symbol: symbol,
                platformId: totalPlatforms,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2
            })
        );
        totalPlatforms++;
        //因为涉及到播放量结算, 所以每个 Platform 拥有相应的稳定币, 并且为其价值背书
        address videoToken = IMurmes(Murmes).videoToken();
        IVT(videoToken).createPlatformToken(
            symbol,
            platfrom,
            totalPlatforms - 1
        );
        emit PlatformJoin(
            platfrom,
            totalPlatforms - 1,
            name,
            symbol,
            rate1,
            rate2
        );
    }

    /**
     * @notice 修改自己 Platform 内的比率, 请至少保证一个非 0, 避免无效修改
     * @param rate1 rateCountsToProfit
     * @param rate2 rateAuditorDivide
     * @return 平台Platform当前最新比率信息
     */
    function platformRate(uint16 rate1, uint16 rate2)
        external
        returns (uint16, uint16)
    {
        require(rate1 != 0 || rate2 != 0, "ER1");
        require(platforms[msg.sender].rateCountsToProfit != 0, "ER2");
        if (rate1 != 0) {
            platforms[msg.sender].rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            platforms[msg.sender].rateAuditorDivide = rate2;
        }
        emit PlatformSetRate(msg.sender, rate1, rate2);
        return (
            platforms[msg.sender].rateCountsToProfit,
            platforms[msg.sender].rateAuditorDivide
        );
    }

    /**
     * @notice 设置一次性结算时 Murmes 中审核员的分成比例
     * @param auditorDivide 新的分成比例
     */
    function setMurmesAuditorDivideRate(uint16 auditorDivide) external auth {
        platforms[Murmes].rateAuditorDivide = auditorDivide;
        emit PlatformSetRate(Murmes, 0, auditorDivide);
    }

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param id 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @return 视频在 Murmes 内的 ID
     */
    function createVideo(
        uint256 id,
        string memory symbol,
        address creator
    ) external returns (uint256) {
        require(platforms[msg.sender].rateCountsToProfit > 0, "ER1");
        uint256 videoId = _createVideo(msg.sender, id, symbol, creator);
        return videoId;
    }

    /**
     * @notice 更新视频的申请信息
     * @param videoId 视频 ID
     * @param tasks 包括新申请在内且根据结算类型排序好的所有申请 ID
     */
    function updateVideoTasks(uint256 videoId, uint256[] memory tasks)
        external
        auth
    {
        videos[videoId].tasks = tasks;
    }

    /**
     * @notice 更新视频的未结算播放量
     * @param videoId 视频 ID
     * @param differ 未结算播放量变化
     */
    function updateVideoUnsettled(uint256 videoId, int256 differ)
        external
        auth
    {
        int256 unsettled = int256(videos[videoId].unsettled) + differ;
        videos[videoId].unsettled = unsettled > 0 ? uint256(unsettled) : 0;
    }

    /**
     * @notice 更改操作员地址
     * @param newOpeator 新的操作员地址
     */
    function changeOpeator(address newOpeator) external onlyOwner {
        opeator = newOpeator;
        emit SystemChangeOpeator(newOpeator);
    }

    /**
     * @notice 获得视频的基本信息
     * @param videoId 视频 ID
     * @return 获得视频的所属平台、在平台内的ID、特征符号、创作者、总播放量、未结算播放量和所有的字幕申请
     */
    function getVideoBaseInfo(uint256 videoId)
        external
        view
        returns (
            address,
            uint256,
            string memory,
            address,
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            videos[videoId].platform,
            videos[videoId].id,
            videos[videoId].symbol,
            videos[videoId].creator,
            videos[videoId].totalViewCouts,
            videos[videoId].unsettled,
            videos[videoId].tasks
        );
    }

    /**
     * @notice 获得平台的基本信息
     * @param platform 平台所有者地址
     * @return 获得平台的名称、符号、ID、播放量收益比、审核员分成比例
     */
    function getPlatformBaseInfo(address platform)
        external
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint16,
            uint16
        )
    {
        return (
            platforms[platform].name,
            platforms[platform].symbol,
            platforms[platform].platformId,
            platforms[platform].rateCountsToProfit,
            platforms[platform].rateAuditorDivide
        );
    }
}
