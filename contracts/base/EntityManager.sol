// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";
import {Constant} from "../libraries/Constant.sol";
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
     * @notice 提交申请时额外条件的集合，id => 说明
     */
    string[] requiresNoteById;
    /**
     * @notice 提交申请时额外条件的映射，说明 => id
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
            emit Events.RegisterRepuire(notes[i], requiresNoteById.length - 1);
        }
    }

    /**
     * @notice 主动加入协议, 并质押一定数目的代币
     * @param user 用户区块链地址
     * @param deposit 质押的代币数量
     * Fn 2
     */
    function userJoin(address user, uint256 deposit) external {
        if (deposit > 0) {
            address token = IComponentGlobal(componentGlobal)
                .defaultDespoitableToken();
            require(
                IERC20(token).transferFrom(msg.sender, address(this), deposit),
                "E212"
            );
        }

        if (users[user].reputation == 0) {
            _userInitialization(user, deposit);
            emit Events.UserJoin(
                user,
                Constant.BASE_REPUTATION,
                int256(deposit)
            );
        } else {
            users[user].deposit += int256(deposit);
            emit Events.UserBaseDataUpdate(user, 0, int256(deposit));
        }
    }

    /**
     * @notice 用户设置自己的用于筛选Item制作者的模块
     * @param guard 新的守护模块地址
     * Fn 3
     */
    function setUserGuard(address guard) external {
        require(users[msg.sender].reputation > 0, "E32");
        users[msg.sender].guard = guard;
        emit Events.UserGuardUpdate(msg.sender, guard);
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
        emit Events.UserWithdrawDeposit(msg.sender, amount);
    }

    /**
     * @notice 更新用户信誉度分数和质押代币数
     * @param user 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）代币数量
     * Fn 5
     */
    function updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) public auth {
        _updateUser(user, reputationSpread, tokenSpread);
        emit Events.UserBaseDataUpdate(user, reputationSpread, tokenSpread);
    }

    /**
     * @notice 更新用户（在平台内的）被锁定代币数量
     * @param platform 平台地址 / 代币合约地址
     * @param day "天"的Unix格式
     * @param amount 有正负（新增或扣除）的锁定的代币数量
     * @param user 用户区块链地址
     * Fn 6
     */
    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address user
    ) public auth {
        require(users[user].reputation != 0, "E62");
        uint256 current = users[user].locks[platform][day];
        int256 newLock = int256(current) + amount;
        users[user].locks[platform][day] = (newLock > 0 ? uint256(newLock) : 0);
        emit Events.UserLockedRevenueUpdate(user, platform, day, amount);
    }

    /**
     * @notice 设置全局管理合约
     * @param note 0为模块管理合约，1为组件管理合约
     * @param addr 相应的合约地址
     * Fn 7
     */
    function setGlobalContract(uint8 note, address addr) external onlyOwner {
        address old;
        if (note == 0) {
            old = moduleGlobal;
            moduleGlobal = addr;
        } else {
            old = componentGlobal;
            componentGlobal = addr;
        }
        operators[addr] = false;
        operators[addr] = true;
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 用户初始化，辅助作用是更新最新操作时间
     * @param user 用户区块链地址
     * @param amount 质押代币数
     * Fn 7
     */
    function _userInitialization(address user, uint256 amount) internal {
        if (users[user].reputation == 0) {
            users[user].reputation = Constant.BASE_REPUTATION;
            users[user].deposit = int256(amount);
        }
        users[user].operate = block.timestamp;
    }

    /**
     * @notice 更新用户基本信息
     * @param user 用户区块链地址
     * @param reputationSpread 信誉度变化
     * @param tokenSpread 质押代币数目变化
     * Fn 8
     */
    function _updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) internal {
        int256 newReputation = int256(users[user].reputation) +
            reputationSpread;
        users[user].reputation = (
            newReputation > 0 ? uint256(newReputation) : 0
        );
        if (tokenSpread < 0) {
            uint256 penalty = uint256(tokenSpread * -1);
            if (users[user].deposit > 0) {
                if (users[user].deposit + tokenSpread < 0) {
                    penalty = uint256(users[user].deposit);
                }
                address vault = IComponentGlobal(componentGlobal).vault();
                address token = IComponentGlobal(componentGlobal)
                    .defaultDespoitableToken();
                require(IERC20(token).transfer(vault, penalty), "E812");
            }
            users[user].deposit = users[user].deposit + tokenSpread;
        }
        if (users[user].reputation == 0) {
            users[user].reputation = 1;
        }
    }

    // ***************** View Functions *****************
    function getUserBaseData(
        address user
    ) external view returns (uint256, int256) {
        return (users[user].reputation, users[user].deposit);
    }

    function getUserGuard(address user) external view returns (address) {
        return users[user].guard;
    }

    function getUserLockReward(
        address user,
        address platform,
        uint256 day
    ) external view returns (uint256) {
        return users[user].locks[platform][day];
    }

    function getRequiresNoteById(
        uint256 requireId
    ) external view returns (string memory) {
        return requiresNoteById[requireId];
    }

    function getRequiresIdByNote(
        string memory note
    ) external view returns (uint256) {
        return requiresIdByNote[note];
    }
}
