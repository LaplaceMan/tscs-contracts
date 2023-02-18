/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-05 20:48:49
 * @Description: 由 Platform 管理自己平台内视频的信息
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract VideoManager {
    /**
     * @notice Murmes 内由 Platform 为视频创作者开启服务的视频总数
     */
    uint256 public totalVideos;

    /**
     * @notice 每个视频都有相应的 Video 结构, 记录其信息, 每个视频有两个 ID, 一个是在 Murmes 内创建时的顺位 ID, 它在 Murmes 内用来唯一标识视频; 另一个是视频在 Platform 中的 ID, 主要与 symbol 结合来区分不同的视频
     */
    mapping(uint256 => Video) videos;

    /**
     * @notice Murmes 内顺位 ID 和 相应 Platform 内 ID 的映射, Platform 区块链地址 => 视频在 Platform 内的 ID => 视频在 Murmes 内的 ID
     */
    mapping(address => mapping(uint256 => uint256)) idReal2System;

    /**
     * @notice 用于存储视频信息
     * @param platform 视频所属 Platform 地址
     * @param id 视频在 Platform 内的 ID （链下决定）
     * @param symbol 用于标识视频的符号
     * @param creator 视频创作者区块链地址
     * @param totalViewCouts 视频总播放量
     * @param unsettled 未结算的视频总播放量
     * @param tasks 已经发出的申请的 ID
     */
    struct Video {
        address platform;
        uint256 id;
        string symbol;
        address creator;
        uint256 totalViewCouts;
        uint256 unsettled;
        uint256[] tasks;
    }

    event VideoCreate(
        address platform,
        uint256 realId,
        uint256 id,
        string symbol,
        address creator,
        uint256 initializeView
    );
    event VideoCountsUpdate(address platform, uint256[] id, uint256[] counts);

    /**
     * @notice 初始化视频结构, 内部功能
     * @param platform 平台Platform地址
     * @param id 视频在 Platform 内的 ID
     * @param symbol 标识视频的符号
     * @param creator 视频创作者地址
     * @param initialize 初始化时（开启服务前）视频播放量
     * @return 视频在 Murmes 内的顺位 ID
     * label V1
     */
    function _createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator,
        uint256 initialize
    ) internal returns (uint256) {
        totalVideos++;
        require(idReal2System[platform][id] == 0, "V1-0");
        videos[totalVideos].platform = platform;
        videos[totalVideos].id = id;
        videos[totalVideos].symbol = symbol;
        videos[totalVideos].creator = creator;
        videos[totalVideos].totalViewCouts = initialize;
        idReal2System[platform][id] = totalVideos;
        emit VideoCreate(
            platform,
            id,
            totalVideos,
            symbol,
            creator,
            initialize
        );
        return totalVideos;
    }

    /**
     * @notice 根据在第三方平台中的ID 获得在Murmes中的顺位视频 ID
     * @param platfrom 第三方平台，视频所属平台
     * @param realId 注册时所填写的视频在平台中的真实 ID
     * @return 在Murmes中的顺位ID
     * label V2
     */
    function getVideoOrderIdByRealId(address platfrom, uint256 realId)
        public
        view
        returns (uint256)
    {
        return idReal2System[platfrom][realId];
    }

    /**
     * @notice 获得视频的基本信息
     * @param videoId 视频 ID
     * @return 获得视频的所属平台、在平台内的ID、特征符号、创作者、总播放量、未结算播放量和所有的字幕申请
     * label V3
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
}
