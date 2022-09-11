// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IVT.sol";
import "../../interfaces/ISubtitleSystem.sol";
import "../../interfaces/ISettlementStrategy.sol";

contract SettlementDivide1 is ISettlementStrategy {
    address public vt;
    address public subtitleSystem;
    mapping(uint256 => SubtitleSettlement) settlements;

    struct SubtitleSettlement {
        uint256 settled;
        uint256 unsettled; //表示未结算的使用量;
    }

    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        address,
        uint256 amount,
        uint256 countsToProfit,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override {
        uint256 subtitleGet = (((countsToProfit *
            settlements[applyId].unsettled) / (10 ^ 6)) * uint16(amount)) /
            (10 ^ 6);
        uint256 length = supporters.length;
        uint256 divide = ((subtitleGet * auditorDivide) / (10 ^ 6) / length);
        ISubtitleSystem(subtitleSystem).preDivideBatch(
            platform,
            supporters,
            divide
        );
        ISubtitleSystem(subtitleSystem).preDivide(
            platform,
            maker,
            subtitleGet - divide * length
        );
        settlements[applyId].unsettled = 0;
    }
}
