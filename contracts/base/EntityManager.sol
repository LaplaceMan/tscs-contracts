// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IModuleGlobal.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";

import {DataTypes} from "../libraries/DataTypes.sol";

contract EntityManager is Ownable {
    /**
     * @notice 负责管理Murmes内模块的合约地址
     */
    address public moduleGlobal;
    /**
     * @notice 负责管理Murmes内组件的合约地址
     */
    address public componentGlobal;
    /**
     * @notice 常用的被除数
     */
    uint16 constant BASE_RATE = 10000;
    /**
     * @notice Murmes内用户信誉度分数初始化为100.0，精度为10
     */
    uint16 constant BASE_REPUTATION = 1000;
    /**
     * @notice 提交申请时额外条件的集合，id => 说明
     */
    string[] requiresNoteById;
    /**
     * @notice 提交申请时额外条件的集合，说明 => id
     */
    mapping(string => uint256) requiresIdByNote;
    /**
     * @notice 记录Murmes内每个用户的信息
     */
    mapping(address => DataTypes.UserStruct) users;

    /**
     * @notice 注册提交申请时所需的额外条件
     * @param notes 文本说明
     * Fn 1
     */
    function registerRequires(string[] memory notes) external {
        for (uint256 i = 0; i < notes.length; i++) {
            require(requiresIdByNote[notes[i]] == 0, "E10");
            requiresNoteById.push(notes[i]);
            requiresIdByNote[notes[i]] = requiresNoteById.length - 1;
        }
    }

    /**
     * @notice 主动加入协议, 并质押一定数目的代币
     * @param usr 用户区块链地址
     * Fn 2
     */
    function userJoin(address usr, uint256 deposit) external {
        if (deposit > 0) {
            address token = IComponentGlobal(componentGlobal)
                .defaultDespoitableToken();
            require(
                IERC20(token).transferFrom(msg.sender, address(this), deposit),
                "E212"
            );
        }

        if (users[usr].reputation == 0) {
            _userInitialization(usr, deposit);
        } else {
            users[usr].deposit += int256(deposit);
        }
    }

    /**
     * @notice 用户设置自己的用于筛选字幕制作者的守护合约
     * @param guard 新的守护合约地址
     * Fn 3
     */
    function setGuard(address guard) external {
        require(users[msg.sender].reputation > 0, "E32");
        users[msg.sender].guard = guard;
    }

    /**
     * @notice 提取质押的代币
     * @param amount 欲提取代币数
     * Fn 4
     */
    function withdrawDeposit(uint256 amount) external {
        require(users[msg.sender].deposit > 0, "E42");
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        require(
            block.timestamp > users[msg.sender].operate + 2 * lockUpTime,
            "E45"
        );
        require(users[msg.sender].deposit - int256(amount) >= 0, "E41");
        users[msg.sender].deposit -= int256(amount);
        address token = IComponentGlobal(componentGlobal)
            .defaultDespoitableToken();
        require(IERC20(token).transfer(msg.sender, amount), "E412");
    }

    /**
     * @notice 更新用户信誉度分数和质押代币数
     * @param usr 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）代币数量
     * Fn 5
     */
    function updaterUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) public auth {
        _updateUser(usr, reputationSpread, tokenSpread);
    }

    /**
     * @notice 更新用户（在平台内的）被锁定代币数量
     * @param platform 平台地址 / 代币合约地址
     * @param day "天"的Unix格式
     * @param amount 有正负（新增或扣除）的代币数量（为锁定状态）
     * @param usr 用户区块链地址
     * Fn 6
     */
    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) public auth {
        require(users[usr].reputation != 0, "E62");
        uint256 current = users[usr].locks[platform][day];
        int256 newLock = int256(current) + amount;
        users[usr].locks[platform][day] = (newLock > 0 ? uint256(newLock) : 0);
    }

    /**
     * @notice 预结算（分发）代币, 因为是先记录, 当达到特定天数后才能正式提取, 所以是 "预"
     * @param platform Platform地址 / 代币合约地址
     * @param to 用户区块链地址
     * @param amount 新增锁定代币数量
     * Fn 7
     */
    function _preDivide(address platform, address to, uint256 amount) internal {
        updateLockReward(platform, block.timestamp / 86400, int256(amount), to);
    }

    /**
     * @notice 同_preDivide(), 只不过同时改变多个用户的状态
     * Fn 8
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
     * @notice 用户初始化，辅助作用是更新最新操作时间
     * @param usr 用户区块链地址
     * @param amount 质押代币数
     * Fn 9
     */
    function _userInitialization(address usr, uint256 amount) internal {
        if (users[usr].reputation == 0) {
            users[usr].reputation = BASE_REPUTATION;
            users[usr].deposit = int256(amount);
        }
        users[usr].operate = block.timestamp;
    }

    /**
     * @notice 更新用户基本信息
     * @param usr 用户区块链地址
     * @param reputationSpread 信誉度变化
     * @param tokenSpread 质押代币数目变化
     */
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
            uint256 penalty = uint256(tokenSpread * -1);
            if (users[usr].deposit > 0) {
                if (users[usr].deposit + tokenSpread < 0) {
                    penalty = uint256(users[usr].deposit);
                }
                address vault = IComponentGlobal(componentGlobal).vault();
                IVault(vault).updatePenalty(penalty);
            }
            users[usr].deposit = users[usr].deposit + tokenSpread;
        }
        if (users[usr].reputation == 0) {
            users[usr].reputation = 1;
        }
    }

    // ***************** View Functions *****************
    function getUserBaseData(
        address usr
    ) external view returns (uint256, int256) {
        return (users[usr].reputation, users[usr].deposit);
    }

    function gutUserGuard(address usr) external view returns (address) {
        return users[usr].guard;
    }

    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) external view returns (uint256) {
        return users[usr].locks[platform][day];
    }

    function getRequireNoteById(
        uint32 requireId
    ) external view returns (string memory) {
        return requiresNoteById[requireId];
    }

    function getRequireIdByNote(
        string memory requireNote
    ) external view returns (uint256) {
        return requiresIdByNote[requireNote];
    }
}
