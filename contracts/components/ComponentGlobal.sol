// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IComponentGlobal.sol";

contract ComponentGlobal is IComponentGlobal {
    address public vault;

    address public access;

    address public version;

    address public platforms;

    address public authority;

    address public arbitration;

    address public itemToken;

    address public platformToken;

    uint256 public lockUpTime;

    event SystemSetComponent(uint8 id, address component);
    event SystemSetLockUpTime(uint256 oldTime, uint256 newTime);

    function setComponent(uint8 note, address addr) external {
        require(address(addr) != address(0), "S11");
        if (note == 0) {
            vault = addr;
        } else if (note == 1) {
            access = addr;
        } else if (note == 2) {
            version = addr;
        } else if (note == 3) {
            platforms = addr;
        } else if (note == 4) {
            authority = addr;
        } else if (note == 5) {
            itemToken = addr;
        } else if (note == 6) {
            platformToken = addr;
        }
        emit SystemSetComponent(note, addr);
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     * label S4
     */
    function setLockUpTime(uint256 time) external {
        require(time > 0, "S41");
        uint256 oldTime = lockUpTime;
        lockUpTime = time;
        emit SystemSetLockUpTime(oldTime, time);
    }
}
