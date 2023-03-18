// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";

interface MurmesInterface {
    function componentGlobal() external view returns (address);

    function owner() external view returns (address);
}

contract DefaultAuthority is IAuthorityBase {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 提交任务之前，判断提交者的权限
     * @param boxId 任务所属Box的ID
     * @param caller 提交众包任务者
     * @return 实际与该众包任务关联Box的ID
     * Fn 1
     */
    function forPostTask(
        address,
        uint256 boxId,
        string memory,
        address caller,
        DataTypes.SettlementType
    ) external override returns (uint256) {
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.creator == caller, "DA15");
        return boxId;
    }

    /**
     * @notice 创建Box之前，判断创建者权限
     * @param platform Box所属的平台地址
     * @param platformId Box所属平台在Murmes内的ID
     * @param caller 创建Box者
     * @return 是否有权限
     * Fn 2
     */
    function forCreateBox(
        address platform,
        uint256 platformId,
        address caller
    ) external view override returns (bool) {
        if (caller != platform || platformId == 0) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 更新Box收益之前，检查更新者权限
     * @param counts 更新的收益数量
     * @param platform Box所属平台
     * @param caller 更新Box收益者
     * @return 最终可更新的收益数量
     */
    function forUpdateBoxRevenue(
        uint256,
        uint256 counts,
        address platform,
        address caller
    ) external override returns (uint256) {
        require(platform == caller, "DA35");
        return counts;
    }
}
