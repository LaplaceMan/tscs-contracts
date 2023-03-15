// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuthorityModule {
    function Murmes() external view returns (address);

    function isOwnCreateBoxAuthority(
        address components,
        address platform,
        uint256 platformId,
        address caller
    ) external view returns (bool);

    function formatCountsOfUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller,
        address components
    ) external returns (uint256);

    function formatBoxIdOfPostTask(
        address components,
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement,
        uint256 amount
    ) external returns (uint256);
}
