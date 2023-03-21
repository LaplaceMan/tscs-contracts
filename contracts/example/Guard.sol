// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGuard.sol";

contract Guard is IGuard {
    mapping(address => bool) whitelist;

    /**
     * @notice 一个用于筛选制作者的守护合约的简单示例，检验Item提交者的权限
     * @param caller Item制作者地址
     * @param reputation Item制作者信誉度分数
     * @param deposit Item制作者质押代币数
     * @param requireId 设置的条件ID
     * @return result 是否符合要求
     */
    function beforeSubmitItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId
    ) external view override returns (bool result) {
        result = true;
        // 当众包人物条件的ID为0时，要求制作者在申请者设置的白名单中
        if (requireId == 0) {
            if (whitelist[caller] != true) result = false;
        }
        // 要求制作者信誉度分数大于50
        if (reputation < 50) result = false;
        // 要求制作者质押的代币数量大于0
        if (deposit <= 0) result = false;
    }

    /**
     * @notice 一个用于筛选制作者的守护合约的简单示例，检验Item审核员的权限
     * @param caller Item制作者地址
     * @param reputation Item制作者信誉度分数
     * @param deposit Item制作者质押代币数
     * @param requireId 设置的条件ID
     * @param attitude 审核员的检测结果
     * @return result 是否符合要求
     */
    function beforeAuditItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId,
        DataTypes.AuditAttitude attitude
    ) external view override returns (bool result) {
        result = true;
        // 当众包人物条件的ID为0时，要求审核员在申请者设置的白名单中
        if (requireId == 0) {
            if (whitelist[caller] != true) result = false;
        }
        // 要求审核员信誉度分数大于50
        if (reputation < 50) result = false;
        // 要求审核员质押的代币数量大于64（精度为18）
        if (deposit < 64 * 10 ** 18) result = false;
        // 可能在公益性质的任务下，不需要举报/反对的操作
        if (attitude == DataTypes.AuditAttitude.OPPOSE) result == false;
    }
}
