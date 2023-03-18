// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthorityBase.sol";

contract MurmesAuthority is IAuthorityBase {
    /**
     * @notice 提交任务之前，判断提交者的权限
     * @param boxId 任务所属Box的ID
     * @param source 众包任务的源地址（详细说明）
     * @param settlement 众包任务所采用的结算策略
     * @return 实际与该众包任务关联Box的ID
     * Fn 1
     */
    function forPostTask(
        address,
        uint256 boxId,
        string memory source,
        address,
        DataTypes.SettlementType settlement
    ) external override returns (uint256) {
        require(settlement == DataTypes.SettlementType.ONETIME, "MA16");
        require(bytes(source).length > 0, "MA11");
        return boxId;
    }

    // Fn 2
    function forCreateBox(
        address,
        uint256,
        address
    ) external view override returns (bool) {
        return false;
    }

    // Fn 3
    function forUpdateBoxRevenue(
        uint256,
        uint256,
        address,
        address
    ) external override returns (uint256) {
        return 0;
    }
}
