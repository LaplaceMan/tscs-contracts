// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPlatforms {
    function createBox(
        uint256 id,
        address from,
        address creator
    ) external returns (uint256);

    function updateBoxTasksByMurmes(
        uint256 boxId,
        uint256[] memory tasks
    ) external;

    function updateBoxesRevenue(
        uint256[] memory ids,
        uint256[] memory
    ) external;

    function updateBoxUnsettledRevenueByMurmes(
        uint256 boxId,
        int256 differ
    ) external;

    function getBox(
        uint256 boxId
    ) external view returns (DataTypes.BoxStruct memory);

    function getPlatform(
        address platform
    ) external view returns (DataTypes.PlatformStruct memory);

    function getPlatformIdByAddress(
        address platform
    ) external view returns (uint256);

    function getBoxTasks(
        uint256 boxId
    ) external view returns (uint256[] memory);
}
