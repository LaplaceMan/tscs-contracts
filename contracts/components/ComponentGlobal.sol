// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IComponentGlobal.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract ComponentGlobal is IComponentGlobal {
    address public Murmes;

    address public vault;

    address public access;

    address public version;

    address public platforms;

    address public settlement;

    address public authority;

    address public arbitration;

    address public itemToken;

    address public platformToken;

    address public defaultDespoitableToken;

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
            platforms = addr;
        } else if (note == 4) {
            settlement = addr;
        } else if (note == 5) {
            authority = addr;
        } else if (note == 6) {
            arbitration = addr;
        } else if (note == 7) {
            itemToken = addr;
        } else if (note == 8) {
            platformToken = addr;
        }
        emit SystemSetComponent(note, addr);
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     * Fn 3
     */
    function setLockUpTime(uint256 time) external auth {
        uint256 oldTime = lockUpTime;
        lockUpTime = time;
        emit SystemSetLockUpTime(oldTime, time);
    }
}
