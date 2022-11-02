/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 15:13:26
 * @Description: 管理 TSCS 所使用的审核策略、访问策略、检测策略和结算策略
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./SubtitleManager.sol";
import "./PlatformManager.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/IAuditStrategy.sol";
import "../interfaces/IDetectionStrategy.sol";
import "../interfaces/ISettlementStrategy.sol";

contract StrategyManager is PlatformManager, SubtitleManager {
    /**
     * @notice 审核策略合约, 根据观众（审核员）评价信息判断字幕状态是否产生变化, 即无变化、被采用或被删除
     */
    IAuditStrategy public auditStrategy;
    /**
     * @notice 访问策略合约, 包括两点: 1.根据信誉度判断用户是否有继续使用 TSCS 服务的资格; 2.根据信誉度和奖惩标志位, 判断用户因为奖励或惩罚后信誉度（与质押ETH数）发生的变化
     */
    IAccessStrategy public accessStrategy;

    /**
     * @notice 检测策略合约, 字幕上传时携带了额外的指纹字段, 目前的设想是其为字幕的 Simhash 值, 该策略是根据已上传字幕的指纹信息判断新上传字幕是否抄袭
     */
    IDetectionStrategy public detectionStrategy;
    /**
     * @notice 结算相关时的除数
     */
    uint16 constant RATE_BASE = 65535;
    /**
     * @notice 锁定期（审核期）
     */
    uint256 public lockUpTime;
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

    event SystemSetZimuToken(address token);
    event SystemSetVideoToken(address token);
    event SystemSetSubtitleToken(address token);
    event SystemSetLockUpTime(uint256 time);
    /**
     * @notice 结算策略 ID 与 SettlementStruct 的映射, 在 TSCS 内用 ID 唯一标识结算策略, 从0开始
     */
    mapping(uint8 => SettlementStruct) public settlementStrategy;

    /**
     * @notice 修改当前 TSCS 内的审核策略, 仅能由管理员调用
     * @param newAudit 新的审核策略合约地址
     */
    function setAuditStrategy(IAuditStrategy newAudit) external onlyOwner {
        require(address(newAudit) != address(0), "ER1");
        auditStrategy = newAudit;
        emit SystemSetAudit(address(newAudit));
    }

    /**
     * @notice 修改当前 TSCS 内的访问策略, 仅能由管理员调用
     * @param newAccess 新的访问策略合约地址
     */
    function setAccessStrategy(IAccessStrategy newAccess) external onlyOwner {
        require(address(newAccess) != address(0), "ER1");
        accessStrategy = newAccess;
        emit SystemSetAccess(address(newAccess));
    }

    /**
     * @notice 修改当前 TSCS 内的检测策略, 仅能由管理员调用
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
        settlementStrategy[strategyId].strategy = strategy;
        settlementStrategy[strategyId].notes = notes;
        if (settlementStrategy[strategyId].strategy != address(0)) {
            opeators[settlementStrategy[strategyId].strategy] = false;
        }
        opeators[strategy] = true;
        emit SystemSetSettlement(strategyId, strategy, notes);
    }

    /**
     * @notice 设置/修改平台币合约地址
     * @param token 新的 ERC20 TSCS 平台币合约地址
     */
    function setZimuToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        zimuToken = token;
        emit SystemSetZimuToken(token);
    }

    /**
     * @notice 设置/修改稳定币合约地址
     * @param token 新的 ERC1155 稳定币合约地址
     */
    function setVideoToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        videoToken = token;
        emit SystemSetVideoToken(token);
    }

    /**
     * @notice 设置/修改字幕代币 NFT 合约地址
     * @param token 新的 ERC1155 稳定币合约地址
     */
    function setSubtitleToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        subtitleToken = token;
        emit SystemSetSubtitleToken(token);
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
    // function getSettlementStrategyBaseInfo(uint8 strategyId)
    //     external
    //     view
    //     returns (address, string memory)
    // {
    //     return (
    //         settlementStrategy[strategyId].strategy,
    //         settlementStrategy[strategyId].notes
    //     );
    // }
}
