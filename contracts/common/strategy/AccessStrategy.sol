// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IAccessStrategy.sol";

contract AccessStrategy is IAccessStrategy {
    uint16 public baseRatio;
    uint16 public baseRepution;
    uint16 public threshold;
    uint256 public minDeposit;
    uint256 public rewardToken;
    uint256 public punishmentToken;
    uint8 public multiplier; // base is 10

    constructor() {
        baseRepution = 100;
        baseRatio = 10 * 100;
        minDeposit = 0.01 ether;
        rewardToken = 0;
        punishmentToken = 0.001 ether;
        multiplier = 15;
    }

    function _reward(uint256 repution) internal view returns (uint256) {
        return (repution / baseRepution);
    }

    function _punishment(uint256 repution) internal view returns (uint256) {
        return (baseRatio / repution);
    }

    function spread(uint256 repution, uint8 flag)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint8
        )
    {
        if (flag == 1) {
            return (_reward(repution), rewardToken, multiplier);
        } else if (flag == 2) {
            if (repution - _punishment(repution) < threshold) {
                return (_punishment(repution), punishmentToken, multiplier);
            }
            return (_punishment(repution), 0, multiplier);
        } else {
            return (0, 0, 0);
        }
    }

    function access(uint256 repution, uint256 deposit)
        external
        view
        override
        returns (bool)
    {
        if ((repution < threshold && deposit <= minDeposit) || repution <= 1) {
            return false;
        } else {
            return true;
        }
    }
}
