// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IVT.sol";
import "../../interfaces/ISubtitleSystem.sol";
import "../../interfaces/ISettlementStrategy.sol";

contract SettlementOneTime2 is ISettlementStrategy {
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
        uint256 amount, //此处表示为总剩余收益
        uint256,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        uint256 subtitleGet;
        if (settlements[applyId].unsettled > 0) {
            if (amount > settlements[applyId].unsettled) {
                subtitleGet = settlements[applyId].unsettled;
                settlements[applyId].unsettled = 0;
                settlements[applyId].settled += settlements[applyId].unsettled;
            } else {
                subtitleGet = amount;
                settlements[applyId].unsettled -= amount;
                settlements[applyId].settled += amount;
            }
            uint256 divide = ((subtitleGet * auditorDivide) /
                65535 /
                supporters.length);
            ISubtitleSystem(subtitleSystem).preDivideBatch(
                platform,
                supporters,
                divide
            );
            ISubtitleSystem(subtitleSystem).preDivide(
                platform,
                maker,
                subtitleGet - divide * supporters.length
            );
        }
        return subtitleGet;
    }

    function updateDebtOrReward(uint256 applyId, uint256 amount) external auth {
        settlements[applyId].unsettled += amount;
    }
}
