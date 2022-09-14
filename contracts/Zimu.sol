/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 19:11:09
 * @Description: TSCS 发行的 ERC20 平台货币 Zim, 代币经济模型仍需设计
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./common/token/ERC20/ERC20.sol";
import "./interfaces/IZimu.sol";

contract ZMToken is ERC20, IZimu {
    /**
     * @notice TSCS 合约地址
     */
    address public subtitleSystem;
    /**
     * @notice 仅能由 TSCS 调用
     */
    modifier auth() {
        require(msg.sender == subtitleSystem);
        _;
    }

    constructor(address ss) ERC20("Zimu Token", "ZM") {
        subtitleSystem = ss;
    }

    /**
     * @notice 为用户铸造一定数目的平台币
     * @param to 平台币接收方
     * @param amount 铸造平台币数目
     */
    function mintReward(address to, uint256 amount) public override auth {
        _mint(to, amount);
    }
}
