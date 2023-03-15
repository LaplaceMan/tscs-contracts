// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPlatforms {
    function Murmes() external view returns (address);

    function createBox(
        uint256 id,
        address from,
        address creator
    ) external returns (uint256);

    function setPlatformRate(uint16 rate1, uint16 rate2) external;

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

    function getBoxTasks(
        uint256 boxId
    ) external view returns (uint256[] memory);

    function getBoxOrderIdByRealId(
        address platfrom,
        uint256 realId
    ) external view returns (uint256);

    function getPlatform(
        address platform
    ) external view returns (DataTypes.PlatformStruct memory);

    function getPlatformRate(
        address platform
    ) external view returns (uint16, uint16);

    function getPlatformIdByAddress(
        address platform
    ) external view returns (uint256);

    function getPlatformAuthorityModule(
        address platform
    ) external view returns (address);
}
