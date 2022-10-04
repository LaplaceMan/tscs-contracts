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
}
