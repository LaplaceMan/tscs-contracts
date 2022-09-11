// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IZimu.sol";

contract EntityManager {
    uint256 public penalty; //罚款总数
    address public zimuToken; //平台币 ERC20
    address public videoToken; //稳定币 ERC1155
    uint16 private _languageType;
    mapping(string => uint16) languages;
    mapping(address => User) users;

    struct User {
        uint256 repution;
        uint256 deposit;
        mapping(address => mapping(uint256 => uint256)) lock;
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
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) internal {
        require(users[usr].repution == 0, "User Initialized");
        uint256 current = users[usr].lock[platform][day];
        users[usr].lock[platform][day] = uint256(int256(current) + amount);
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

    function _day() internal view returns (uint256) {
        return block.timestamp / 86400;
    }

    function _preDivide(
        address platform,
        address to,
        uint256 amount
    ) internal {
        _updateLockReward(platform, _day(), int256(amount), to);
    }

    function _preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < to.length; i++) {
            _updateLockReward(platform, _day(), int256(amount), to[i]);
        }
    }
}
