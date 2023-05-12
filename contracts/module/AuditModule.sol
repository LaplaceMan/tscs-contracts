// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuditModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AuditModule is IAuditModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 审核/检测的基本数目
     */
    uint256 public auditUnit;

    constructor(address ms, uint256 unit) {
        Murmes = ms;
        auditUnit = unit;
    }

    /**
     * @notice 设置新的审核/检测基本数目
     * @param newAuditUnit 新的审核/检测基本数目
     */
    function changeAuditUnit(uint256 newAuditUnit) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ATM5");
        auditUnit = newAuditUnit;
        emit SetAuditUnit(newAuditUnit);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 判断Item是否被采纳
     * @param uploaded 众包任务下已上传的Item总数
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @param allSupport 众包任务下已上传的Item获得的总支持数
     * @return state 最新的Item状态
     */
    function _adopt(
        uint256 uploaded,
        uint256 support,
        uint256 oppose,
        uint256 allSupport
    ) internal view returns (DataTypes.ItemState state) {
        if (uploaded > 1) {
            if (
                support > auditUnit &&
                ((support - oppose) >= (allSupport / uploaded))
            ) {
                state = DataTypes.ItemState.ADOPTED;
            }
        } else {
            if (
                support > auditUnit &&
                (((support - oppose) * 10) / (support + oppose) >= 6)
            ) {
                state = DataTypes.ItemState.ADOPTED;
            }
        }
    }

    /**
     * @notice 判断Item是否被“删除”
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @return state 最新的Item状态
     */
    function _delete(
        uint256 support,
        uint256 oppose
    ) internal view returns (DataTypes.ItemState state) {
        if (support > 1) {
            if (oppose >= (auditUnit * support) / 2 + support) {
                state = DataTypes.ItemState.DELETED;
            }
        } else {
            if (oppose >= auditUnit + 1) {
                state = DataTypes.ItemState.DELETED;
            }
        }
    }

    // ***************** View Functions *****************
    /**
     * @notice 获得Item被审核/检测后的最新状态
     * @param uploaded 众包任务下已上传的Item总数
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @param allSupport 众包任务下已上传的Item获得的总支持数
     * @param uploadTime Item上传时间
     * @param lockUpTime 审核/锁定期
     * @return state 最新的Item状态
     */
    function afterAuditItem(
        uint256 uploaded,
        uint256 support,
        uint256 oppose,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view override returns (DataTypes.ItemState) {
        DataTypes.ItemState state1;
        if (block.timestamp >= uploadTime + lockUpTime) {
            state1 = _adopt(uploaded, support, oppose, allSupport);
        }
        DataTypes.ItemState state2 = _delete(support, oppose);
        if (state1 != DataTypes.ItemState.NORMAL) {
            return state1;
        } else if (state2 != DataTypes.ItemState.NORMAL) {
            return state2;
        } else {
            return DataTypes.ItemState.NORMAL;
        }
    }
}
