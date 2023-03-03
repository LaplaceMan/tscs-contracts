/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-05 19:48:53
 * @Description: 管理 Platform, 包括添加和修改相关参数
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatformToken.sol";
import "../interfaces/IComponentGlobal.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract Platforms {
    address public Murmes;
    uint256 public totalBoxes;
    uint256 public totalPlatforms;

    mapping(uint256 => DataTypes.BoxStruct) boxes;
    mapping(address => DataTypes.PlatformStruct) platforms;
    mapping(address => mapping(uint256 => uint256)) idRealToMurmes;

    constructor(address ms) {
        Murmes = ms;
        platforms[ms].name = "Murmes";
        platforms[ms].symbol = "Murmes";
        platforms[ms].rateAuditorDivide = 100;
    }

    function addPlatfrom(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external {
        require(rate1 > 0 && rate2 > 0, "P1-1");
        require(IMurmes(Murmes).owner() == msg.sender, "P1-5");
        require(platforms[platfrom].platformId == 0, "P1-0");
        totalPlatforms++;
        platforms[platfrom] = (
            DataTypes.PlatformStruct({
                name: name,
                symbol: symbol,
                platformId: totalPlatforms,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2
            })
        );
        address component = IMurmes(Murmes).componentGlobal();
        address platformToken = IComponentGlobal(component).platformToken();
        IPlatformToken(platformToken).createPlatformToken(
            symbol,
            platfrom,
            totalPlatforms
        );
    }

    function setPlatformRate(uint16 rate1, uint16 rate2) external {
        require(rate1 != 0 || rate2 != 0, "P2-1");
        require(platforms[msg.sender].platformId != 0, "P2-2");
        if (rate1 != 0) {
            platforms[msg.sender].rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            platforms[msg.sender].rateAuditorDivide = rate2;
        }
        emit PlatformSetRate(msg.sender, rate1, rate2);
    }

    function setMurmesAuditorDivideRate(uint16 auditorDivide) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P3-5");
        platforms[Murmes].rateAuditorDivide = auditorDivide;
        emit PlatformSetRate(Murmes, 0, auditorDivide);
    }

    function createBox(
        uint256 id,
        address from,
        address creator
    ) external returns (uint256) {
        // address authority = IMurmes(Murmes).authorityStrategy();
        // IAuthorityStrategy(authority).isOwnCreateVideoAuthority(
        //     platforms[msg.sender].rateCountsToProfit,
        //     msg.sender
        // );
        if (!IMurmes(Murmes).isOperator(msg.sender)) from = msg.sender;
        uint256 boxId = _createBox(from, id, creator);
        return boxId;
    }

    function updateBoxTasks(uint256 boxId, uint256[] memory tasks) external {
        require(msg.sender == Murmes, "P6-5");
        boxes[boxId].tasks = tasks;
    }

    function updateBoxUnsettledRevenue(uint256 boxId, int256 differ) external {
        require(msg.sender == Murmes, "P7-5");
        int256 unsettled = int256(videos[videoId].unsettled) + differ;
        boxes[boxId].unsettled = unsettled > 0 ? uint256(unsettled) : 0;
    }

    function updateBoxesExternalRevenue(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        assert(ids.length == amounts.length);
        address authority = IMurmes(Murmes).authorityStrategy();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 amount = IAuthorityStrategy(authority)
                .isOwnUpdateViewCountsAuthority(
                    videos[ids[i]].id,
                    amounts[i],
                    videos[ids[i]].platform,
                    msg.sender
                );
            videos[ids[i]].unsettled += amount;
            for (uint256 j; j < videos[ids[i]].tasks.length; j++) {
                uint256 taskId = videos[ids[i]].tasks[j];
                (uint8 strategy, , uint256[] memory itemIds) = IMurmes(Murmes)
                    .getTaskPaymentStrategyAndSubtitles(taskId);
                if (strategy == 1 && itemIds.length > 0) {
                    uint16 rateCountsToProfit = platforms[
                        videos[itemIds[i]].platform
                    ].rateCountsToProfit;
                    IMurmes(Murmes).updateUsageCounts(
                        taskId,
                        amount,
                        rateCountsToProfit
                    );
                }
            }
        }

        emit VideoCountsUpdate(videos[id[0]].platform, id, vs);
    }

    function _createBox(
        address platform,
        uint256 realId,
        address creator
    ) internal returns (uint256) {
        totalBoxes++;
        require(idRealToMurmes[platform][realId] == 0, "V1-0");
        boxes[totalBoxes].platform = platform;
        boxes[totalBoxes].id = id;
        boxes[totalBoxes].creator = creator;
        idRealToMurmes[platform][realId] = totalBoxes;
        return totalBoxes;
    }

    function getBoxOrderIdByRealId(address platfrom, uint256 realId)
        public
        view
        returns (uint256)
    {
        return idRealToMurmes[platfrom][realId];
    }

    function getBox(uint256 boxId) external view returns (DataTypes.BoxStruct) {
        return boxes[boxId];
    }

    function getPlatform(address platform)
        external
        view
        returns (DataTypes.PlatformStruct)
    {
        return platforms[platform];
    }

    function getPlatformIdByAddress(address platform)
        external
        view
        returns (uint256)
    {
        return platforms[platform].platformId;
    }

    function getBoxTasks(uint256 boxId) external view returns (uint256 memory) {
        return boxes[boxId].tasks;
    }
}
