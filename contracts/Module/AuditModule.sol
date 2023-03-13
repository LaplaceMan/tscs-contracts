// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAuditModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AuditModule is IAuditModule {
    address public Murmes;

    uint256 public auditUnit;

    constructor(address ms, uint256 unit) {
        Murmes = ms;
        auditUnit = unit;
    }

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

    function changeAuditUnit(uint256 newAuditUnit) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ATM5");
        auditUnit = newAuditUnit;
        emit SystemChangeAuditUnit(newAuditUnit);
    }
}
