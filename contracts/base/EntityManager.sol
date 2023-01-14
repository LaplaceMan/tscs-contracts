/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 18:33:27
 * @Description: 管理 Murmes 内代币合约地址、语言和用户信息
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IZimu.sol";
import "../interfaces/IVault.sol";
import "../common/utils/Ownable.sol";

contract EntityManager is Ownable {
    /**
     * @notice TSCS代币 ERC20合约地址
     */
    address public zimuToken;
    /**
     * @notice Platform稳定币 ERC1155合约地址
     */
    address public videoToken;
    /**
     * @notice Murmes 金库
     */
    address public vault;
    /**
     * @notice 管理 Platform 和 Video
     */
    address public platforms;
    /**
     * @notice Murmers DAO 仲裁合约
     */
    address public arbitration;
    /**
     * @notice 用户加入生态时在 Murmes 内质押的 Zimu 总数
     */
    uint256 public deposit;
    /**
     * @notice 根据语言 ID 获得语言类型
     */
    string[] languageNote;
    /**
     * @notice 手续费用比率
     */
    uint16 public fee;
    /**
     * @notice Murmes 内用户初始化时的信誉度分数, 精度为 1 即 100.0
     */
    uint16 constant baseReputation = 1000;
    /**
     * @notice 计算费用时的除数
     */
    uint16 constant BASE_FEE_RATE = 10000;
    /**
     * @notice 语言名称与对应ID（注册顺序）的映射, 从1开始（ISO 3166-1 alpha-2 code）
     */
    mapping(string => uint32) languages;
    /**
     * @notice 每个区块链地址与 User 结构的映射
     */
    mapping(address => User) users;
    /**
     * @notice 每个用户在TSCS内的行为记录
     * @param reputation 信誉度分数
     * @param operate 用户在协议内执行重要操作的时间
     * @param deposit 已质押以太数, 为负表示负债
     * @param lock 平台区块链地址 => 天（Unix）=> 锁定稳定币数量，Default 为 0x0
     */
    struct User {
        uint256 reputation;
        uint256 operate;
        int256 deposit;
        mapping(address => mapping(uint256 => uint256)) lock;
    }

    event RegisterLanguage(string language, uint16 id);
    event UserJoin(address user, uint256 reputation, int256 deposit);
    event UserLockRewardUpdate(
        address user,
        address platform,
        uint256 day,
        int256 reward
    );
    event UserInfoUpdate(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    );
    event UserWithdrawDespoit(address user, uint256 amount, uint256 balance);

    /**
     * @notice 为了节省存储成本, 使用ID（uint16）代替语言文本（string）, 同时任何人可调用, 保证适用性
     * @param language 欲添加语言类型
     * @return 新添加语言的ID
     */
    function registerLanguage(string[] memory language)
        external
        returns (uint16)
    {
        for (uint256 i; i < language.length; i++) {
            languageNote.push(language[i]);
            require(languages[language[i]] == 0, "ER0");
            languages[language[i]] = uint16(languageNote.length - 1);
            emit RegisterLanguage(language[i], uint16(languageNote.length - 1));
        }
        return uint16(languageNote.length - 1);
    }

    /**
     * @notice 根据 ID 获得相应语言的文字类型
     * @param languageId 欲查询语言 Id
     * @return 语言类型
     */
    function getLanguageNoteById(uint16 languageId)
        external
        view
        returns (string memory)
    {
        return languageNote[languageId];
    }

    /**
     * @notice 根据类型 Type 获得相应语言的 ID
     * @param language 语言的类型（文字描述）
     * @return 语言注册 ID
     */
    function getLanguageIdByNote(string memory language)
        external
        view
        returns (uint32)
    {
        return languages[language];
    }

    /**
     * @notice 为用户初始化User结构
     * @param usr 用户区块链地址
     * @param amount 质押代币数
     */
    function _userInitialization(address usr, int256 amount) internal {
        if (users[usr].reputation == 0) {
            users[usr].reputation = baseReputation;
            users[usr].deposit = amount;
            emit UserJoin(usr, users[usr].reputation, users[usr].deposit);
        }
        users[usr].operate = block.timestamp;
    }

    /**
     * @notice 主动加入TSCS, 并质押一定数目的 Zimu
     * @param usr 用户区块链地址
     */
    function userJoin(address usr, uint256 deposit_) external {
        IZimu(zimuToken).transferFrom(msg.sender, vault, deposit_);
        if (users[usr].reputation == 0) {
            _changeDespoit(int256(deposit_));
            _userInitialization(usr, int256(deposit_));
        } else {
            //当已加入时, 仍可调用此功能增加质押 Zimu 数
            users[usr].deposit += int256(deposit_);
            _changeDespoit(int256(deposit_));
            emit UserInfoUpdate(
                usr,
                int256(users[usr].reputation),
                users[usr].deposit
            );
        }
    }

    /**
     * @notice 更新用户在平台内的锁定稳定币数量（每个Platform都有属于自己的稳定币, 各自背书）
     * @param platform 平台地址, 地址0指TSCS本身
     * @param day 天 的Unix格式
     * @param amount 有正负（新增或扣除）的稳定币数量（为锁定状态）
     * @param usr 用户区块链地址
     */
    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) public auth {
        require(users[usr].reputation != 0, "ER0");
        uint256 current = users[usr].lock[platform][day];
        int256 newLock = int256(current) + amount;
        users[usr].lock[platform][day] = (newLock > 0 ? uint256(newLock) : 0);
        emit UserLockRewardUpdate(usr, platform, day, amount);
    }

    /**
     * @notice 更新用户信誉度分数和质押 Zimu 数
     * @param usr 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）Zimu 数量
     */
    function updaterUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) public auth {
        _updateUser(usr, reputationSpread, tokenSpread);
    }

    function _updateUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) internal {
        int256 newReputation = int256(users[usr].reputation) + reputationSpread;
        users[usr].reputation = (
            newReputation > 0 ? uint256(newReputation) : 0
        );
        if (tokenSpread < 0) {
            //小于0意味着惩罚操作, 扣除质押Zimu数
            int256 despoit_ = tokenSpread;
            uint256 penalty_ = uint256(tokenSpread * -1);
            if (users[usr].deposit > 0) {
                if (users[usr].deposit + tokenSpread < 0) {
                    penalty_ = uint256(users[usr].deposit);
                    despoit_ = users[usr].deposit * -1;
                }
                IVault(vault).changePenalty(penalty_);
                _changeDespoit(despoit_);
            }
            users[usr].deposit = users[usr].deposit + tokenSpread;
        } else {
            //此处待定, 临时设计为奖励操作时, 给与特定数目的平台币Zimu Token
            IZimu(zimuToken).mintReward(usr, uint256(tokenSpread));
        }
        //用户的最小信誉度为1, 这样是为了便于判断用户是否已加入系统（User结构已经初始化过）
        if (users[usr].reputation == 0) {
            users[usr].reputation = 1;
        }
        emit UserInfoUpdate(usr, reputationSpread, tokenSpread);
    }

    /**
     * @notice 根据区块链时间戳获得 当天 的Unix格式
     * @return 天 Unix格式
     */
    function _day() internal view returns (uint256) {
        return block.timestamp / 86400;
    }

    /**
     * @notice 预结算（分发）稳定币, 因为是先记录, 当达到特定天数后才能正式提取, 所以是 "预"
     * @param platform Platform地址
     * @param to 用户区块链地址
     * @param amount 新增稳定币数量（为锁定状态）
     */
    function _preDivide(
        address platform,
        address to,
        uint256 amount
    ) internal {
        updateLockReward(platform, _day(), int256(amount), to);
    }

    /**
     * @notice 同_preDivide(), 只不过同时改变多个用户的状态
     */
    function _preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < to.length; i++) {
            updateLockReward(platform, _day(), int256(amount), to[i]);
        }
    }

    /**
     * @notice 更改 Murmes 内质押的 Zimu 数量
     * @param amount 变化数量
     */
    function _changeDespoit(int256 amount) internal {
        if (amount != 0) {
            int256 newAmount = int256(deposit) + amount;
            deposit = newAmount > 0 ? uint256(newAmount) : 0;
        }
    }

    /**
     * @notice 获得特定用户当前信誉度分数和质押 Zimu 数量
     * @param usr 欲查询用户的区块链地址
     * @return 信誉度分数, 质押 Zimu 数
     */
    function getUserBaseInfo(address usr)
        external
        view
        returns (uint256, int256)
    {
        return (users[usr].reputation, users[usr].deposit);
    }

    /**
     * @notice 获取用户在指定平台指定日子锁定的稳定币数量
     * @param usr 欲查询用户的区块链地址
     * @param platform 特定Platform地址
     * @param day 指定天
     * @return 锁定稳定币数量
     */
    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) external view returns (uint256) {
        return users[usr].lock[platform][day];
    }
}
