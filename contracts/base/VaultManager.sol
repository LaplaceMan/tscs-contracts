/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-22 12:52:13
 * @Description: 管理 TSCS 内的资产
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract VaultManager {
    /**
     * @notice 用户加入生态时在 TSCS 内质押的 Zimu 数
     */
    uint256 public Despoit;
    /**
     * @notice TSCS内产生的罚款总数（以Zimu计价）
     */
    uint256 public penalty;

    /**
     * @notice 手续费用比率
     */
    uint256 fee;

    /**
     * @notice 计算费用时的除数
     */
    uint256 constant BASE_FEE_RATE = 10000;

    /**
     * @notice 来自于不同平台的手续费收入
     */
    mapping(uint256 => uint256) feeIncome;

    /**
     * @notice 更改 TSCS 内质押的 Zimu 数量
     * @param amount 变化数量
     */
    function _changeDespoit(int256 amount) internal {
        if (amount != 0) {
            Despoit = uint256(int256(Despoit) + amount);
        }
    }

    /**
     * @notice TSCS 内罚没 Zimu 资产
     * @param amount 新增罚没 Zimu 数量
     */
    function _changePenalty(uint256 amount) internal {
        penalty += amount;
        _changeDespoit(int256(amount) * -1);
    }

    /**
     * @notice 新增手续费，内部功能
     * @param platformId 新增手续费来源平台
     * @param amount 新增手续费数量
     */
    function _addFee(uint256 platformId, uint256 amount) internal {
        feeIncome[platformId] += amount;
    }
}
