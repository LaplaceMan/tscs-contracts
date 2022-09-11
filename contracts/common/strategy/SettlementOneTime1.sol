// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IVT.sol";
import "../../interfaces/ISubtitleSystem.sol";
import "../../interfaces/ISettlementStrategy.sol";

contract SettlementOneTime0 is ISettlementStrategy {
    address public subtitleSystem;
    address public vt;
    mapping(uint256 => SubtitleSettlement) settlements;

    struct SubtitleSettlement {
        uint256 settled;
        uint256 unsettled;
    }

    modifier auth() {
        require(msg.sender == subtitleSystem, "No Permission");
        _;
    }

    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        address,
        uint256 amount,
        uint256,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth {
        if (settlements[applyId].settled < amount) {
            uint256 supporterGet = (amount * auditorDivide) / (10 ^ 6);
            uint256 unit = supporterGet / supporters.length;

            ISubtitleSystem(subtitleSystem).preDivide(
                platform,
                maker,
                amount - unit * supporters.length
            );
            ISubtitleSystem(subtitleSystem).preDivideBatch(
                platform,
                supporters,
                unit
            );
            settlements[applyId].settled += amount;
        }
    }

    function updateDebtOrReward(uint256 applyId, uint256 amount) external auth {
        settlements[applyId].unsettled += amount;
    }
}
