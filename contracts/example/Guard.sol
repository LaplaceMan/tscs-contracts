// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IGuard.sol";

contract Guard is IGuard {
    mapping(address => bool) whitelist;

    /**
     * @notice 一个用于筛选字幕制作者的守护合约的简单示例
     * @param caller 字幕制作者地址
     * @param reputation 字幕制作者信誉度分数
     * @param deposit 字幕制作者质押代币数
     * @param languageId 申请的语言 ID
     * @return result 是否符合要求
     */
    function check(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint32 languageId
    ) external view returns (bool result) {
        result = true;
        // 当申请制作ID为0的语言的字幕时，要求字幕制作者在申请者设置的白名单中
        if (languageId == 0) {
            if (whitelist[caller] != true) result = false;
        }
        // 要求字幕制作者信誉度分数大于50
        if (reputation < 50) result = false;
        // 要求字幕制作者质押的Zimu代币数量大于0
        if (deposit <= 0) result = false;
    }
}
