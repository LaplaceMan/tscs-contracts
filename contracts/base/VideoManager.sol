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
    mapping(uint256 => Video) videos;

    /**
     * @notice TSCS 内顺位 ID 和 相应 Platform 内 ID 的映射, Platform 区块链地址 => 视频在 Platform 内的 ID => 视频在 TSCS 内的 ID
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
        uint256 reealId,
        uint256 id,
        string symbol,
        address creator,
        uint256 counts
    );

    event VideoCountsUpdate(address platform, uint256[] id, uint256[] counts);

    /**
     * @notice 初始化视频结构, 内部功能
     * @param platform 平台Platform地址
     * @param id 视频在 Platform 内的 ID
     * @param symbol 标识视频的符号
     * @param creator 视频创作者地址
     * @param total 视频当前总播放量
     * @return 视频在 TSCS 内的顺位 ID
     */
    function _createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator,
        uint256 total
    ) internal returns (uint256) {
        totalVideoNumber++;
        require(idReal2System[msg.sender][id] == 0, "ER0");
        videos[totalVideoNumber].platform = platform;
        videos[totalVideoNumber].id = id;
        videos[totalVideoNumber].symbol = symbol;
        videos[totalVideoNumber].creator = creator;
        videos[totalVideoNumber].totalViewCouts = total;
        idReal2System[msg.sender][id] = totalVideoNumber;
        emit VideoCreate(
            platform,
            id,
            totalVideoNumber,
            symbol,
            creator,
            total
        );
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
}
