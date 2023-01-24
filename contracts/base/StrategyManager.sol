/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 15:13:26
 * @Description: 管理 Murmes 所使用的审核策略、访问策略、检测策略和结算策略
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./EntityManager.sol";
import "./SubtitleManager.sol";
import "../interfaces/IVT.sol";
import "../interfaces/IPlatform.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/IAuditStrategy.sol";
import "../interfaces/IDetectionStrategy.sol";
import "../interfaces/ISettlementStrategy.sol";

contract StrategyManager is EntityManager, SubtitleManager {
    /**
     * @notice 审核策略合约, 根据观众（审核员）评价信息判断字幕状态是否产生变化, 即无变化、被采用或被删除
     */
    IAuditStrategy public auditStrategy;
    /**
     * @notice 访问策略合约, 包括两点: 1.根据信誉度判断用户是否有继续使用 Murmes 服务的资格; 2.根据信誉度和奖惩标志位, 判断用户因为奖励或惩罚后信誉度（与质押ETH数）发生的变化
     */
    IAccessStrategy public accessStrategy;

    /**
     * @notice 检测策略合约, 字幕上传时携带了额外的指纹字段, 目前的设想是其为字幕的 Simhash 值, 该策略是根据已上传字幕的指纹信息判断新上传字幕是否抄袭
     */
    IDetectionStrategy public detectionStrategy;
    /**
     * @notice 锁定期（审核期）
     */
    uint256 public lockUpTime;
    /**
     * @notice 结算相关时的除数
     */
    uint16 constant RATE_BASE = 65535;
    /**
     * @notice 记录每个结算策略的信息
     * @param strategy 结算策略合约地址
     * @param notes 结算策略合约注释说明
     */
    struct SettlementStruct {
        address strategy;
        string notes;
    }

    event SystemSetAudit(address newAudit);
    event SystemSetAccess(address newAccess);
    event SystemSetDetection(address newDetection);
    event SystemSetSettlement(uint8 strategyId, address strategy, string notes);

    event SystemSetFee(uint16 old, uint16 fee);
    event SystemSetLockUpTime(uint256 time);
    event SystemSetAddress(uint8 id, address addr);

    /**
     * @notice 结算策略 ID 与 SettlementStruct 的映射, 在 Murmes 内用 ID 唯一标识结算策略, 从0开始
     */
    mapping(uint8 => SettlementStruct) settlementStrategy;

    /**
     * @notice 修改当前 Murmes 内的审核策略, 仅能由管理员调用
     * @param newAudit 新的审核策略合约地址
     */
    function setAuditStrategy(IAuditStrategy newAudit) external onlyOwner {
        require(address(newAudit) != address(0), "ER1");
        auditStrategy = newAudit;
        emit SystemSetAudit(address(newAudit));
    }

    /**
     * @notice 修改当前 Murmes 内的访问策略, 仅能由管理员调用
     * @param newAccess 新的访问策略合约地址
     */
    function setAccessStrategy(IAccessStrategy newAccess) external onlyOwner {
        require(address(newAccess) != address(0), "ER1");
        accessStrategy = newAccess;
        emit SystemSetAccess(address(newAccess));
    }

    /**
     * @notice 修改当前 Murmes 内的检测策略, 仅能由管理员调用
     * @param newDetection 新的检测策略合约地址
     */
    function setDetectionStrategy(IDetectionStrategy newDetection)
        external
        onlyOwner
    {
        require(address(newDetection) != address(0), "ER1");
        detectionStrategy = newDetection;
        emit SystemSetDetection(address(newDetection));
    }

    /**
     * @notice 添加或修改结算策略
     * @param strategyId 新的结算合约ID, 无顺位关系
     * @param strategy  新的结算合约地址
     * @param notes 新的结算策略注释说明
     */
    function setSettlementStrategy(
        uint8 strategyId,
        address strategy,
        string memory notes
    ) external onlyOwner {
        require(strategy != address(0), "ER1");
        if (settlementStrategy[strategyId].strategy != address(0)) {
            _replaceOperator(settlementStrategy[strategyId].strategy, strategy);
        }
        _setOperator(strategy);
        settlementStrategy[strategyId].strategy = strategy;
        settlementStrategy[strategyId].notes = notes;
        emit SystemSetSettlement(strategyId, strategy, notes);
    }

    /**
     * @notice 设置 Murmes 组件的合约地址
     * @param note 0 为 Zimu 代币合约地址；1 为 VT 代币合约地址；2 为 ST 代币合约地址；3 为金库合约地址；4 为平台管理合约地址；5 为仲裁合约地址
     * @param addr 新的合约地址
     */
    function setComponentsAddress(uint8 note, address addr) external onlyOwner {
        require(addr != address(0), "ER1");
        if (note == 0) {
            zimuToken = addr;
        } else if (note == 1) {
            videoToken = addr;
        } else if (note == 2) {
            subtitleToken = addr;
        } else if (note == 3) {
            vault = addr;
        } else if (note == 4) {
            if (platforms != address(0)) {
                _replaceOperator(platforms, addr);
            } else {
                _setOperator(addr);
            }
            platforms = addr;
        } else if (note == 5) {
            if (arbitration != address(0)) {
                _replaceOperator(platforms, addr);
            } else {
                _setOperator(addr);
            }
            arbitration = addr;
        } else if (note == 6) {
            versionManagement = addr;
        }
        emit SystemSetAddress(note, addr);
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     */
    function setLockUpTime(uint256 time) external onlyOwner {
        require(time > 0, "ER1");
        lockUpTime = time;
        emit SystemSetLockUpTime(time);
    }

    /**
     * @notice 返回指定结算策略的基本信息
     * @param strategyId 策略 ID
     * @return 结算策略合约地址和注释说明
     */
    function getSettlementStrategyBaseInfo(uint8 strategyId)
        external
        view
        returns (address, string memory)
    {
        return (
            settlementStrategy[strategyId].strategy,
            settlementStrategy[strategyId].notes
        );
    }

    /**
     * @notice 当 DAO 判定字幕为恶意时，删除字幕，由于加密思想，我们并没有在链上删掉ST的信息，而是在本系统内作标记，将不再认可它
     * @param id 恶意ST ID
     */
    function holdSubtitleStateByDAO(uint256 id, uint8 state) external auth {
        assert(state == 0 || state == 2);
        _changeST(id, state);
    }

    /**
     * @notice 提取质押的 Zimu 代币
     * @param amount 欲提取 Zimu 代币数
     */
    function withdrawDeposit(uint256 amount) external {
        require(users[msg.sender].deposit > 0, "ER1");
        require(
            users[msg.sender].operate + 2 * lockUpTime < block.timestamp,
            "ER5"
        );
        if (amount > uint256(users[msg.sender].deposit)) {
            amount = uint256(users[msg.sender].deposit);
        }
        users[msg.sender].deposit -= int256(amount);
        IVault(vault).withdrawDeposit(zimuToken, msg.sender, amount);
        emit UserWithdrawDespoit(
            msg.sender,
            amount,
            uint256(users[msg.sender].deposit)
        );
    }

    /**
     * @notice 设置手续费，大于0时开启，等于0时关闭
     * @param rate 手续费比率，若为1%，应设置为100，因为计算后的值为 100/BASE_FEE_RATE
     */
    function setFee(uint16 rate) external onlyOwner {
        uint16 old = fee;
        fee = rate;
        emit SystemSetFee(old, rate);
    }
}
