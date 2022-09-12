// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IZimu.sol";

contract EntityManager {
    /*
     * @description: TSCS内产生的罚款总数（以ETH计价）
     */
    uint256 public penalty;
    /*
     * @description: TSCS代币 ERC20合约地址
     */
    address public zimuToken;
    /*
     * @description: Platform稳定币 ERC1155合约地址
     */
    address public videoToken;
    /*
     * @description: 已注册的语言总数
     */
    uint16 public languageTypes;
    /*
     * @description: 语言名称与对应ID（注册顺序）的映射, 从1开始
     */
    mapping(string => uint16) languages;
    /*
     * @description: 每个区块链地址与 User 结构的映射
     */
    mapping(address => User) users;
    /*
     * @param {repution} 信誉度分数
     * @param {deposit} 已质押以太数
     * @param {lock} 区块链地址 => 天（Unix）=> 锁定稳定币数量
     * @description: 每个用户在TSCS内的行为记录
     */
    struct User {
        uint256 repution;
        uint256 deposit;
        mapping(address => mapping(uint256 => uint256)) lock;
    }

    /*
     * @param {language} 欲添加语言类型
     * @return {新添加语言的ID}
     * @description: 为了节省存储成本, 使用ID（uint16）代替语言文本（string）, 同时任何人可调用, 保证适用性
     */
    function registerLanguage(string memory language)
        external
        returns (uint16)
    {
        languageTypes++;
        require(languages[language] == 0, "Have Register");
        languages[language] = languageTypes;
        return languageTypes;
    }

    /*
     * @param {usr} 用户区块链地址
     * @param {amount} 质押代币数
     * @description: 为用户初始化User结构
     */
    function _userInitialization(address usr, uint256 amount) internal {
        if (users[usr].repution == 0) {
            users[usr].repution = 100;
            users[usr].deposit = amount;
        }
    }

    /*
     * @param {usr} 用户区块链地址
     * @description: 主动加入TSCS, 并质押一定数目的ETH
     */
    function userJoin(address usr) external payable {
        if (users[usr].repution == 0) {
            _userInitialization(usr, msg.value);
        } else {
            users[usr].deposit += msg.value;
        }
    }

    /*
     * @param {platform} 平台地址, 地址0指TSCS本身
     * @param {day} 天 的Unix格式
     * @param {amount} 有正负（新增或扣除）的稳定币数量（为锁定状态）
     * @param {usr} 用户区块链地址
     * @description: 更新用户在平台内的锁定稳定币数量（每个Platform都有属于自己的稳定币, 各自背书）
     */
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

    /*
     * @param {usr} 用户区块链地址
     * @param {reputionSpread} 有正负（增加或扣除）的信誉度分数
     * @param {tokenSpread} 有正负的（增加或扣除）ETH数量
     * @description: 更新用户信誉度分数和质押ETH数
     */
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

    /*
     * @return 天 Unix格式
     * @description: 根据区块链时间戳获得 当天 的Unix格式
     */
    function _day() internal view returns (uint256) {
        return block.timestamp / 86400;
    }

    /*
     * @param {platform} Platform地址
     * @param {to} 用户区块链地址
     * @param {amount} 新增稳定币数量（为锁定状态）
     * @description: 预结算（分发）稳定币, 因为是先记录, 当达到特定天数后才能正式提取, 所以是 "预"
     */
    function _preDivide(
        address platform,
        address to,
        uint256 amount
    ) internal {
        _updateLockReward(platform, _day(), int256(amount), to);
    }

    /*
     * @description: 同_preDivide(), 只不过同时改变多个用户的状态
     */
    function _preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < to.length; i++) {
            _updateLockReward(platform, _day(), int256(amount), to[i]);
        }
    }

    /*
     * @param {usr} 欲查询用户的区块链地址
     * @return 信誉度分数, 质押ETH数
     * @description: 获得特定用户当前信誉度分数和质押ETH数量
     */
    function getUserBaseInfo(address usr)
        public
        view
        returns (uint256, uint256)
    {
        return (users[usr].repution, users[usr].deposit);
    }

    /*
     * @param {usr} 欲查询用户的区块链地址
     * @param {platform} 特定Platform地址
     * @param {day} 指定天
     * @return 锁定稳定币数量
     * @description: 获取用户在指定平台指定日子锁定的稳定币数量
     */
    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) public view returns (uint256) {
        return users[usr].lock[platform][day];
    }
}
