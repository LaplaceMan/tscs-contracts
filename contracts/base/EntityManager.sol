/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 18:33:27
 * @Description: 管理 Murmes 内代币合约地址、语言和用户信息
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/IComponentGlobal.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract EntityManager is Ownable {
    address public moduleGlobal;
    address public componentGlobal;

    uint16 constant BASE_RATE = 10000;
    uint16 constant BASE_REPUTATION = 1000;

    string[] requiresNoteById;
    mapping(string => uint256) requiresIdByNote;

    mapping(address => DataTypes.UserStruct) users;

    event RegisterRepuire(string require, uint256 id);
    event UserJoin(address usr, uint256 reputation, int256 deposit);
    event UserLockRewardUpdate(
        address usr,
        address platform,
        uint256 day,
        int256 reward
    );
    event UserInfoUpdate(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    );
    event UserWithdrawDespoit(address usr, uint256 amount, uint256 balance);

    function registerRequires(string[] memory notes) external {
        for (uint256 i = 0; i < notes.length; i++) {
            requiresNoteById.push(notes[i]);
            require(requiresIdByNote[notes[i]] == 0, "E10");
            requiresIdByNote[notes[i]] = requiresNoteById.length - 1;
            emit RegisterRepuire(notes[i], requiresNoteById.length - 1);
        }
    }

    /**
     * @notice 用户设置自己的用于筛选字幕制作者的守护合约
     * @param guard 新的守护合约地址
     * label E14
     */
    function setGuard(address guard) external {
        require(users[msg.sender].reputation > 0, "E141");
        users[msg.sender].guard = guard;
    }

    /**
     * @notice 主动加入TSCS, 并质押一定数目的 Zimu
     * @param usr 用户区块链地址
     * label E5
     */
    function userJoin(address usr, uint256 deposit) external {
        if (deposit > 0) {
            // 质押平台要求的代币
            // require(
            //     IZimu(zimuToken).transferFrom(msg.sender, vault, deposit_),
            //     "E512"
            // );
        }

        if (users[usr].reputation == 0) {
            _userInitialization(usr, int256(deposit));
        } else {
            users[usr].deposit += int256(deposit);
            emit UserInfoUpdate(
                usr,
                int256(users[usr].reputation),
                users[usr].deposit
            );
        }
    }

    /**
     * @notice 提取质押的 Zimu 代币
     * @param amount 欲提取 Zimu 代币数
     * label S7
     */
    function withdrawDeposit(uint256 amount) external {
        require(users[msg.sender].deposit > 0, "S71");
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        require(
            users[msg.sender].operate + 2 * lockUpTime < block.timestamp,
            "S75"
        );
        if (amount > uint256(users[msg.sender].deposit)) {
            amount = uint256(users[msg.sender].deposit);
        }
        users[msg.sender].deposit -= int256(amount);
        // IVault(vault).withdrawDeposit(zimuToken, msg.sender, amount);
        emit UserWithdrawDespoit(
            msg.sender,
            amount,
            uint256(users[msg.sender].deposit)
        );
    }

    /**
     * @notice 更新用户信誉度分数和质押 Zimu 数
     * @param usr 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）Zimu 数量
     * label E7
     */
    function updaterUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) public auth {
        _updateUser(usr, reputationSpread, tokenSpread);
    }

    /**
     * @notice 更新用户在平台内的锁定稳定币数量（每个Platform都有属于自己的稳定币, 各自背书）
     * @param platform 平台地址, 地址0指TSCS本身
     * @param day 天 的Unix格式
     * @param amount 有正负（新增或扣除）的稳定币数量（为锁定状态）
     * @param usr 用户区块链地址
     * label E6
     */
    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) public auth {
        require(users[usr].reputation != 0, "E60");
        uint256 current = users[usr].locks[platform][day];
        int256 newLock = int256(current) + amount;
        users[usr].locks[platform][day] = (newLock > 0 ? uint256(newLock) : 0);
        emit UserLockRewardUpdate(usr, platform, day, amount);
    }

    /**
     * @notice 预结算（分发）稳定币, 因为是先记录, 当达到特定天数后才能正式提取, 所以是 "预"
     * @param platform Platform地址
     * @param to 用户区块链地址
     * @param amount 新增稳定币数量（为锁定状态）
     * label E10
     */
    function _preDivide(
        address platform,
        address to,
        uint256 amount
    ) internal {
        updateLockReward(platform, block.timestamp / 86400, int256(amount), to);
    }

    /**
     * @notice 同_preDivide(), 只不过同时改变多个用户的状态
     * label E11
     */
    function _preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < to.length; i++) {
            updateLockReward(
                platform,
                block.timestamp / 86400,
                int256(amount),
                to[i]
            );
        }
    }

    /**
     * @notice 为用户初始化User结构
     * @param usr 用户区块链地址
     * @param amount 质押代币数
     * label E4
     */
    function _userInitialization(address usr, int256 amount) internal {
        if (users[usr].reputation == 0) {
            users[usr].reputation = BASE_REPUTATION;
            users[usr].deposit = amount;
            emit UserJoin(usr, users[usr].reputation, users[usr].deposit);
        }
        users[usr].operate = block.timestamp;
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
            //小于0意味着惩罚操作, 扣除质押资产
            int256 despoit_ = tokenSpread;
            uint256 penalty_ = uint256(tokenSpread * -1);
            if (users[usr].deposit > 0) {
                if (users[usr].deposit + tokenSpread < 0) {
                    penalty_ = uint256(users[usr].deposit);
                    despoit_ = users[usr].deposit * -1;
                }
                address vault = IComponentGlobal(componentGlobal).vault();
                IVault(vault).changePenalty(penalty_);
            }
            users[usr].deposit = users[usr].deposit + tokenSpread;
        }
        //用户的最小信誉度为1, 这样是为了便于判断用户是否已加入系统（User结构已经初始化过）
        if (users[usr].reputation == 0) {
            users[usr].reputation = 1;
        }
        emit UserInfoUpdate(usr, reputationSpread, tokenSpread);
    }

    /**
     * @notice 获得特定用户当前信誉度分数和质押 Zimu 数量
     * @param usr 欲查询用户的区块链地址
     * @return 信誉度分数, 质押 Zimu 数
     * label E13
     */
    function getUserBaseInfo(address usr)
        external
        view
        returns (uint256, int256)
    {
        return (users[usr].reputation, users[usr].deposit);
    }

    /**
     * @notice 获得指定用户当前启用的守护合约地址
     * @param usr 用户地址
     * @return 当前使用的守护合约
     * label E15
     */
    function gutUserGuard(address usr) external view returns (address) {
        return users[usr].guard;
    }

    /**
     * @notice 获取用户在指定平台指定日子锁定的稳定币数量
     * @param usr 欲查询用户的区块链地址
     * @param platform 特定Platform地址
     * @param day 指定天
     * @return 锁定稳定币数量
     * label E16
     */
    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) external view returns (uint256) {
        return users[usr].locks[platform][day];
    }

    function getRequireNoteById(uint32 requireId)
        external
        view
        returns (string memory)
    {
        return requiresNoteById[requireId];
    }

    function getRequireIdByNote(string memory requireNote)
        external
        view
        returns (uint256)
    {
        return requiresIdByNote[requireNote];
    }
}
