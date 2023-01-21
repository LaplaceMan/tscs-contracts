/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 14:44:30
 * @Description: Murmes 内默认的字幕审核策略, 设计逻辑可参阅论文
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAuditStrategy.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AuditStrategy is IAuditStrategy {
    /**
     * @notice 协议主合约地址
     */
    address public Murmes;
    /**
     * @notice 判断状态改变所需审核数量的基本单元，测试时为 2，正常时为 10
     */
    uint256 public auditUnit;

    event SystemChangeAuditUnit(uint256 now);

    constructor(address ms, uint256 unit) {
        Murmes = ms;
        auditUnit = unit;
    }

    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕是否被采纳, 内部功能
     * @param uploaded 已上传的字幕数目
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @param allSupport 相应申请下所有字幕获得支持数的和
     * @return 返回 0 表示字幕状态不变化, 返回 1 表示字幕被采纳（申请被确认）
     */
    function _adopt(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport
    ) internal view returns (uint8) {
        uint8 flag = 0;
        if (uploaded > 1) {
            if (
                support > auditUnit &&
                ((support - against) >= (allSupport / uploaded))
            ) {
                flag = 1;
            }
        } else {
            // 在测试时将其修改为 1, 默认为 10
            if (
                support > auditUnit &&
                (((support - against) * 10) / (support + against) >= 6)
            ) {
                flag = 1;
            }
        }
        return flag;
    }

    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕是否被认定为恶意字幕, 内部功能
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @return 返回 0 表示字幕状态不变化, 返回 2 表示字幕被认定为恶意字幕
     */
    function _delete(uint256 support, uint256 against)
        internal
        view
        returns (uint8)
    {
        uint8 flag = 0;
        if (support > 1) {
            if (against >= (auditUnit * support) / 2 + support) {
                flag = 2;
            }
        } else {
            if (against >= auditUnit + 1) {
                flag = 2;
            }
        }
        return flag;
    }

    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕状态是否发生变化
     * @param uploaded 相应申请下已经上传的字幕数量
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @param allSupport 相应申请下所有字幕获得支持数的和
     * @param uploadTime 字幕上传时间
     * @param lockUpTime Murmes 内设置的锁定期/审核期
     * @return 返回 0 表示状态不变化, 返回 1 表示字幕被采纳（申请被采纳）, 返回 2 表示字幕被认定为恶意字幕
     */
    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view override returns (uint8) {
        uint8 flag1 = 0;
        if (block.timestamp >= uploadTime + lockUpTime) {
            flag1 = _adopt(uploaded, support, against, allSupport);
        }
        uint8 flag2 = _delete(support, against);
        if (flag1 != 0) {
            return flag1;
        } else if (flag2 != 0) {
            return flag2;
        } else {
            return 0;
        }
    }

    /**
     * @notice 修改基本（最小）审核数量
     * @param newAuditUnit 新的基本（最小）审核数量
     */
    function changeAuditUnit(uint256 newAuditUnit) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ER5");
        auditUnit = newAuditUnit;
        emit SystemChangeAuditUnit(newAuditUnit);
    }
}
