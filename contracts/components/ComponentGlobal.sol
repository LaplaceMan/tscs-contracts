// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IComponentGlobal.sol";
import {Events} from "../libraries/Events.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function setOperatorByTool(address old, address replace) external;
}

contract ComponentGlobal is IComponentGlobal {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 金库模块合约地址
     */
    address public vault;
    /**
     * @notice 访问控制模块合约地址
     */
    address public access;
    /**
     * @notice Item版本管理模块合约地址
     */
    address public version;
    /**
     * @notice 平台管理模块合约地址
     */
    address public platforms;
    /**
     * @notice 收益结算模块合约地址
     */
    address public settlement;
    /**
     * @notice 特殊权限管理模块合约地址
     */
    address public authority;
    /**
     * @notice 仲裁模块合约地址
     */
    address public arbitration;
    /**
     * @notice Item NFT合约地址
     */
    address public itemToken;
    /**
     * @notice 平台代币合约地址
     */
    address public platformToken;
    /**
     * @notice 默认支持的用于质押的代币类型
     */
    address public defaultDespoitableToken;
    /**
     * @notice 审核期
     */
    uint256 public lockUpTime;

    constructor(address ms, address token) {
        Murmes = ms;
        defaultDespoitableToken = token;
    }

    // Fn 1
    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "C15");
        _;
    }

    /**
     * @notice 设置Murmes组件的合约地址
     * @param note 说明
     * @param addr 合约地址
     * Fn 2
     */
    function setComponent(uint8 note, address addr) external auth {
        if (note == 0) {
            vault = addr;
        } else if (note == 1) {
            access = addr;
        } else if (note == 2) {
            version = addr;
        } else if (note == 3) {
            MurmesInterface(Murmes).setOperatorByTool(platforms, addr);
            platforms = addr;
        } else if (note == 4) {
            MurmesInterface(Murmes).setOperatorByTool(settlement, addr);
            settlement = addr;
        } else if (note == 5) {
            MurmesInterface(Murmes).setOperatorByTool(authority, addr);
            authority = addr;
        } else if (note == 6) {
            MurmesInterface(Murmes).setOperatorByTool(arbitration, addr);
            arbitration = addr;
        } else if (note == 7) {
            itemToken = addr;
        } else if (note == 8) {
            platformToken = addr;
        }
        emit Events.MurmesSetComponent(note, addr);
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     * Fn 3
     */
    function setLockUpTime(uint256 time) external auth {
        uint256 oldTime = lockUpTime;
        lockUpTime = time;
        emit Events.MurmesSetLockUpTime(oldTime, time);
    }
}
