// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IZimu.sol";

contract EntityManager {
    uint256 public penalty;
    address public zimuToken;
    uint16 private _languageType;
    mapping(string => uint16) languages;
    mapping(address => User) users;

    struct User {
        uint256 repution;
        uint256 deposit;
        mapping(uint16 => mapping(uint256 => uint256)) lock;
    }

    function registerLanguage(string memory language)
        external
        returns (uint256)
    {
        _languageType++;
        require(languages[language] == 0, "Have Register");
        languages[language] = _languageType;
        return _languageType;
    }

    function _userInitialization(address usr, uint256 amount) internal {
        if (users[usr].repution == 0) {
            users[usr].repution = 100;
            users[usr].deposit = amount;
        }
    }

    function userJoin() external payable {
        if (users[msg.sender].repution == 0) {
            _userInitialization(msg.sender, msg.value);
        } else {
            users[msg.sender].deposit += msg.value;
        }
    }

    function _updateLockReward(
        uint16 platformId,
        uint256 day,
        int256 amount,
        address usr
    ) internal {
        require(users[usr].repution == 0, "User Initialized");
        uint256 current = users[usr].lock[platformId][day];
        users[usr].lock[platformId][day] = uint256(int256(current) + amount);
    }

    function _updateUser(
        address usr,
        int256 reputionSpread,
        int256 tokenSpread
    ) internal {
        users[usr].repution = uint256(
            int256(users[usr].repution) + reputionSpread
        );
        if (tokenSpread < 0) {
            users[usr].deposit = uint256(
                int256(users[usr].deposit) + tokenSpread
            );
            penalty += uint256(tokenSpread);
        }
        IZimu(zimuToken).mintReward(usr, uint256(tokenSpread));
        if (users[usr].repution == 0) {
            users[usr].repution = 1;
        }
    }
}
