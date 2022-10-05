/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-05 19:48:53
 * @Description: 管理 Platform, 包括添加和修改相关参数
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/utils/Ownable.sol";
import "./VideoManager.sol";
import "./EntityManager.sol";
import "../interfaces/IVT.sol";

contract PlatformManager is Ownable, EntityManager {
    /**
     * @notice 已加入的 Platform 总数
     */
    uint256 public totalPlatforms;
    /**
     * @notice Platform 地址与相应结构体的映射
     */
    mapping(address => Platform) public platforms;
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
     * @notice 由 TSCS 管理员操作, 添加新 Platform 生态
     * @param platfrom Platform区块链地址,
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rate1 rateCountsToProfit 值必须大于0
     * @param rate2 rateAuditorDivide 值必须大于0
     * @return 平台Platform唯一标识ID（加入顺位）
     */
    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external onlyOwner returns (uint256) {
        require(platforms[platfrom].rateCountsToProfit == 0, "ER0");
        require(rate1 > 0 && rate2 > 0, "ER1");
        totalPlatforms++;
        platforms[platfrom] = (
            Platform({
                name: name,
                symbol: symbol,
                platformId: totalPlatforms,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2
            })
        );
        //因为涉及到播放量结算, 所以每个 Platform 拥有相应的稳定币, 并且为其价值背书
        IVT(videoToken).createPlatformToken(symbol, platfrom, totalPlatforms);
        emit PlatformJoin(platfrom, totalPlatforms, name, symbol, rate1, rate2);
        return totalPlatforms;
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
     * @notice 获得 Platform 基本信息
     * @param platform 欲查询的 Platform 区块链地址
     * @return 平台platform的名称、符号、ID、播放量稳定币比率、审核分成比例
     */
    // function getPlatformBaseInfo(address platform)
    //     external
    //     view
    //     returns (
    //         string memory,
    //         string memory,
    //         uint256,
    //         uint16,
    //         uint16
    //     )
    // {
    //     return (
    //         platforms[platform].name,
    //         platforms[platform].symbol,
    //         platforms[platform].platformId,
    //         platforms[platform].rateCountsToProfit,
    //         platforms[platform].rateAuditorDivide
    //     );
    // }
}
