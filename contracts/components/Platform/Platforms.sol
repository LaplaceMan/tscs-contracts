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
import "../../interfaces/IAuthorityStrategy.sol";

contract Platforms is VideoManager {
    /**
     * @notice 已加入的 Platform 总数
     */
    address public Murmes;
    /**
     * @notice 已加入的 Platform 总数
     */
    uint256 public totalPlatforms;

    /**
     * @notice 默认的第三方平台中涉及兑换代币（VT价值转换）时，要求的目标代币
     */
    address public tokenGlobal;
    /**
     * @notice Platform 地址与相应结构体的映射
     */
    mapping(address => Platform) platforms;

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
    event PlatformSetTokenGlobal(address oldToken, address newToken);

    constructor(address ms, address token) {
        Murmes = ms;
        tokenGlobal = token;
        // 当结算类型为一次性结算时, 默认字幕支持者分成 1/100
        platforms[ms].rateAuditorDivide = 655;
        platforms[ms].name = "Murmes";
        platforms[ms].symbol = "Murmes";
        // Default 索引为 0，但包括在总数内
        totalPlatforms += 1;
        emit PlatformJoin(ms, 0, "Murmes", "Murmes", 0, 655);
    }

    /**
     * @notice 由 Murmes 管理员操作, 添加新 Platform 生态
     * @param platfrom Platform区块链地址,
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rate1 rateCountsToProfit 值必须大于0
     * @param rate2 rateAuditorDivide 值必须大于0
     * label P1
     */
    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P1-5");
        require(platforms[platfrom].rateCountsToProfit == 0, "P1-0");
        require(rate1 > 0 && rate2 > 0, "P1-1");
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
     * label P2
     */
    function platformRate(uint16 rate1, uint16 rate2)
        external
        returns (uint16, uint16)
    {
        require(rate1 != 0 || rate2 != 0, "P2-1");
        require(platforms[msg.sender].rateCountsToProfit != 0, "P2-2");
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
     * label P3
     */
    function setMurmesAuditorDivideRate(uint16 auditorDivide) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P3-5");
        platforms[Murmes].rateAuditorDivide = auditorDivide;
        emit PlatformSetRate(Murmes, 0, auditorDivide);
    }

    /**
     * @notice 在第三方平台中涉及到VT的价值转换时，要求目标代币类型
     * @param token 目标代币类型，默认为 Zimu
     * label P4
     */
    function setTokenGlobal(address token) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P4-5");
        address old = tokenGlobal;
        tokenGlobal = token;
        emit PlatformSetTokenGlobal(old, token);
    }

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param id 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @param initialize 初始化时（开启服务前）视频播放量
     * @return 视频在 Murmes 内的 ID
     * label P5
     */
    function createVideo(
        uint256 id,
        string memory symbol,
        address creator,
        uint256 initialize,
        address from
    ) external returns (uint256) {
        address authority = IMurmes(Murmes).authorityStrategy();
        IAuthorityStrategy(authority).isOwnCreateVideoAuthority(
            platforms[msg.sender].rateCountsToProfit,
            msg.sender
        );
        if (!IMurmes(Murmes).isOperator(msg.sender)) from = msg.sender;
        uint256 videoId = _createVideo(from, id, symbol, creator, initialize);
        return videoId;
    }

    /**
     * @notice 更新视频的申请信息
     * @param videoId 视频 ID
     * @param tasks 包括新申请在内且根据结算类型排序好的所有申请 ID
     * label P6
     */
    function updateVideoTasks(uint256 videoId, uint256[] memory tasks)
        external
    {
        require(msg.sender == Murmes, "P6-5");
        videos[videoId].tasks = tasks;
    }

    /**
     * @notice 更新视频的未结算播放量
     * @param videoId 视频 ID
     * @param differ 未结算播放量变化
     * label P7
     */
    function updateVideoUnsettled(uint256 videoId, int256 differ) external {
        require(msg.sender == Murmes, "P7-5");
        int256 unsettled = int256(videos[videoId].unsettled) + differ;
        videos[videoId].unsettled = unsettled > 0 ? uint256(unsettled) : 0;
    }

    /**
     * @notice 更新视频播放量, 此处为新增量, 仅能由视频所属的 Platform 调用
     * @param id 视频在 Murmes 内的 ID
     * @param vs 新增播放量
     * label P8
     */
    function updateViewCounts(uint256[] memory id, uint256[] memory vs)
        external
    {
        assert(id.length == vs.length);
        address authority = IMurmes(Murmes).authorityStrategy();
        for (uint256 i = 0; i < id.length; i++) {
            uint256 amount = IAuthorityStrategy(authority)
                .isOwnUpdateViewCountsAuthority(
                    videos[id[i]].id,
                    vs[i],
                    videos[id[i]].platform,
                    msg.sender
                );
            videos[id[i]].totalViewCouts += amount;
            videos[id[i]].unsettled += amount;
            for (uint256 j; j < videos[id[i]].tasks.length; j++) {
                uint256 taskId = videos[id[i]].tasks[j];
                (uint8 strategy, , uint256[] memory ids) = IMurmes(Murmes)
                    .getTaskPaymentStrategyAndSubtitles(taskId);
                if (strategy == 1 && ids.length > 0) {
                    uint16 rateCountsToProfit = platforms[
                        videos[id[i]].platform
                    ].rateCountsToProfit;
                    IMurmes(Murmes).updateUsageCounts(
                        taskId,
                        vs[i],
                        rateCountsToProfit
                    );
                }
            }
        }

        emit VideoCountsUpdate(videos[id[0]].platform, id, vs);
    }

    /**
     * @notice 获得平台的基本信息
     * @param platform 平台所有者地址
     * @return 获得平台的名称、符号、ID、播放量收益比、审核员分成比例
     * label P9
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

    /**
     * @notice 根据第三方平台的地址获得平台/代币 ID
     * @param platform 平台地址
     * @return 平台/代币 ID
     * label P10
     */
    function getPlatformIdByAddress(address platform)
        external
        view
        returns (uint256)
    {
        return platforms[platform].platformId;
    }
}
