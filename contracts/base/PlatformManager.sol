// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Ownable.sol";
import "./VideoManager.sol";

contract PlatfromManage is Ownable {
    uint256 public totalPlatfroms;
    mapping(address => Platform) platforms;

    struct Platform {
        string name;
        string symbol;
        uint256 join;
        address manager;
        bool run;
    }

    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external auth {
        require(platforms[platfrom].join == 0, "Have Joined");
        VideoManager vm = new VideoManager(platfrom, rate1, rate2);
        platforms[platfrom] = (
            Platform({
                name: name,
                symbol: symbol,
                join: block.timestamp,
                manager: address(vm),
                run: true
            })
        );
    }

    function platfromStop(address platfrom) external auth {
        require(platforms[platfrom].run == true, "Had Stop Or Not Join");
        platforms[platfrom].run = false;
    }
}
