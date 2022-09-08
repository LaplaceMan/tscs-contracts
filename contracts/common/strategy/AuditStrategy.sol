// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IAuditStrategy.sol";

contract GeneralStrategy is IAuditStrategy {
    function _adopt(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport
    ) internal pure returns (uint8) {
        uint8 flag;
        if (uploaded > 1) {
            if (
                support > 1 && ((support - against) > (allSupport / uploaded))
            ) {
                flag = 1;
            }
        } else {
            if (
                support > 10 &&
                (((support - against) * 10) / (support + against) >= 6)
            ) {
                flag = 1;
            }
        }
        return flag;
    }

    function _delete(uint256 support, uint256 against)
        internal
        pure
        returns (uint8)
    {
        uint8 flag;
        if (support > 1) {
            if (against >= 10 * support) {
                flag = 2;
            }
        } else {
            if (against >= 10) {
                flag = 2;
            }
        }
        return flag;
    }

    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport
    ) external pure override returns (uint8) {
        uint8 flag1 = _adopt(uploaded, support, against, allSupport);
        uint8 flag2 = _delete(support, against);
        if (flag1 != 0) {
            return flag1;
        } else if (flag2 != 0) {
            return flag2;
        } else {
            return 0;
        }
    }
}
