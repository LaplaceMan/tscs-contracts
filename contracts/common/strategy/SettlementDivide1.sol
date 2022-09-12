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
        uint256 amount, //此处为分成比例
        uint256,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        //字幕使用量是视频播放量的子集
        uint256 subtitleGet = ((settlements[applyId].unsettled) *
            uint16(amount)) / (10 ^ 6);
        uint256 divide = ((subtitleGet * auditorDivide) /
            (10 ^ 6) /
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
        settlements[applyId].unsettled = 0;
        return subtitleGet;
    }

    function updateDebtOrReward(uint256 applyId, uint256 amount) external auth {
        settlements[applyId].unsettled += amount;
    }
}
