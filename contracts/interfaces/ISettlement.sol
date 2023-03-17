// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ISettlement {
    function updateItemRevenue(uint256 taskId, uint256 counts) external;
}
