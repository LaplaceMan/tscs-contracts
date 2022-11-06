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
     * @notice TSCS 内由 Platform 为视频创作者开启服务的视频总数
     */
    uint256 public totalVideoNumber;

    /**
     * @notice 每个视频都有相应的 Video 结构, 记录其信息, 每个视频有两个 ID, 一个是在 TSCS 内创建时的顺位 ID, 它在 TSCS 内用来唯一标识视频; 另一个是视频在 Platform 中的 ID, 主要与 symbol 结合来区分不同的视频
     */
    mapping(uint256 => Video) public videos;

    /**
     * @notice TSCS 内顺位 ID 和 相应 Platform 内 ID 的映射, Platform 区块链地址 => 视频在 Platform 内的 ID => 视频在 TSCS 内的 ID
     */
    mapping(address => mapping(uint256 => uint256)) idReal2System;
    /**
     * @notice appplyId 与视频链接的映射
     */
    mapping(uint256 => string) defaultSrc;

    /**
     * @notice 用于存储视频信息
     * @param platform 视频所属 Platform 地址
     * @param id 视频在 Platform 内的 ID （链下决定）
     * @param symbol 用于标识视频的符号
     * @param creator 视频创作者区块链地址
     * @param totalViewCouts 视频总播放量
     * @param unsettled 未结算的视频总播放量
     * @param applys 已经发出的申请的 ID
     */
    struct Video {
        address platform;
        uint256 id;
        string symbol;
        address creator;
        uint256 totalViewCouts;
        uint256 unsettled;
        uint256[] applys;
    }

    event VideoCreate(
        address platform,
        uint256 realId,
        uint256 id,
        string symbol,
        address creator
    );

    event VideoCountsUpdate(address platform, uint256[] id, uint256[] counts);

    /**
     * @notice 初始化视频结构, 内部功能
     * @param platform 平台Platform地址
     * @param id 视频在 Platform 内的 ID
     * @param symbol 标识视频的符号
     * @param creator 视频创作者地址
     * @return 视频在 TSCS 内的顺位 ID
     */
    function _createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator
    ) internal returns (uint256) {
        totalVideoNumber++;
        require(idReal2System[platform][id] == 0, "ER0");
        videos[totalVideoNumber].platform = platform;
        videos[totalVideoNumber].id = id;
        videos[totalVideoNumber].symbol = symbol;
        videos[totalVideoNumber].creator = creator;
        idReal2System[platform][id] = totalVideoNumber;
        emit VideoCreate(platform, id, totalVideoNumber, symbol, creator);
        return totalVideoNumber;
    }

    /**
     * @notice 更新视频播放量, 此处为新增量, 仅能由视频所属的 Platform 调用
     * @param id 视频在 TSCS 内的 ID
     * @param vs 新增播放量
     */
    function updateViewCounts(uint256[] memory id, uint256[] memory vs)
        external
    {
        assert(id.length == vs.length);
        for (uint256 i = 0; i < id.length; i++) {
            require(msg.sender == videos[id[i]].platform, "ER5");
            videos[id[i]].totalViewCouts += vs[i];
            videos[id[i]].unsettled += vs[i];
        }
        emit VideoCountsUpdate(videos[id[0]].platform, id, vs);
    }

    /**
     * @notice 设置视频源链接，适用于最普遍的申请情况
     * @param applyId 申请的唯一 ID
     * @param src 视频源链接
     */
    function _addDefaultSrc(uint256 applyId, string memory src) internal {
        defaultSrc[applyId] = src;
    }

    /**
     * @notice 当视频所属平台未加入生态或视频未被平台注册时，需要辅助字段即视频链接来唯一确定
     * @param applyId 申请的唯一 ID
     * @return 视频链接
     */
    function getDefaultVideoSrc(uint256 applyId)
        public
        view
        returns (string memory)
    {
        require(bytes(defaultSrc[applyId]).length > 0, "ER1");
        return defaultSrc[applyId];
    }
}
