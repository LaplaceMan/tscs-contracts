// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAccessModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AccessModule is IAccessModule {
    address public Murmes;

    uint32 constant BASE_RATIO = 100000;

    uint16 constant BASE_REPUTATION = 100;

    uint16 constant depositThreshold = 600;

    uint8 constant blacklistThreshold = 1;

    uint8 public multiplier;

    uint256 public depositUnit;

    uint256 public punishmentUnit;

    constructor(address ms) {
        Murmes = ms;
        depositUnit = 32 * 10 ** 18;
        multiplier = 150;
        punishmentUnit = 1 * 10 ** 17;
    }

    // Fn 1
    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ASM15");
        _;
    }

    function reward(uint256 reputation) public pure returns (uint256) {
        return (reputation / BASE_REPUTATION);
    }

    function punishment(uint256 reputation) public pure returns (uint256) {
        return (BASE_RATIO / reputation);
    }

    function deposit(uint256 reputation) public view returns (uint256) {
        if (reputation >= depositThreshold) {
            return 0;
        } else {
            uint256 baseRate = (depositThreshold - reputation) / 100;
            return depositUnit * (2 ** baseRate);
        }
    }

    function variation(
        uint256 reputation,
        uint8 flag
    ) external view override returns (uint256, uint256) {
        if (flag == 1) {
            return (reward(reputation), 0);
        } else if (flag == 2) {
            if (reputation < depositThreshold) {
                uint256 thisPunishment = punishment(reputation);
                return (thisPunishment, thisPunishment * punishmentUnit);
            } else {
                return (punishment(reputation), 0);
            }
        } else {
            return (0, 0);
        }
    }

    function access(
        uint256 reputation,
        int256 token
    ) external view override returns (bool) {
        if (
            (reputation <= depositThreshold &&
                token <= int256(deposit(reputation))) ||
            reputation <= blacklistThreshold
        ) {
            return false;
        } else {
            return true;
        }
    }

    function auditable(int256 token) external view override returns (bool) {
        return (token >= int256(depositUnit));
    }

    function lastReputation(
        uint256 reputation,
        uint8 flag
    ) public pure override returns (uint256) {
        uint256 last = 0;
        if (flag == 2) {
            uint256 _4ac = 4 * BASE_RATIO;
            uint256 _sqrtb2_4ac = _sqrt(reputation * reputation + _4ac);
            last = (reputation + _sqrtb2_4ac) / 2;
        } else if (flag == 1) {
            uint256 _base = BASE_REPUTATION + 1;
            uint256 _up = reputation * BASE_REPUTATION;
            last = _up / _base;
        }
        return last;
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function setDepositUnit(uint256 newDepositUnit) external auth {
        depositUnit = newDepositUnit;
        emit SystemSetDepositUnit(newDepositUnit);
    }

    function setPunishmentUnit(uint256 newPunishmentUnit) external auth {
        punishmentUnit = newPunishmentUnit;
        emit SystemSetPunishmentUnit(newPunishmentUnit);
    }

    function setMultiplier(uint8 newMultiplier) external auth {
        multiplier = newMultiplier;
        emit SystemSetMultiplier(newMultiplier);
    }
}
