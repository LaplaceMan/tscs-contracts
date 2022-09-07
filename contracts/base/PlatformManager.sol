// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Ownable.sol";
import "./VideoManager.sol";

contract PlatformManager is Ownable {
    uint256 public totalPlatforms;
    mapping(address => Platform) platforms;
    struct Platform {
        string name;
        string symbol;
        uint16 rateCountsToProfit;
        uint16 rateAuditorDivide;
    }

    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external auth {
        require(platforms[platfrom].rateCountsToProfit == 0, "Have Joined");
        require(rate1 > 0 && rate2 > 0, "Invaild Rate");
        totalPlatforms++;
        platforms[platfrom] = (
            Platform({
                name: name,
                symbol: symbol,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2
            })
        );
    }

    function platformRate(uint16 rate1, uint16 rate2) external {
        require(rate1 != 0 || rate2 != 0, "Invaild Rate");
        require(
            platforms[msg.sender].rateCountsToProfit != 0,
            "Platform Not Existence"
        );
        if (rate1 != 0) {
            platforms[msg.sender].rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            platforms[msg.sender].rateAuditorDivide = rate2;
        }
    }
}
