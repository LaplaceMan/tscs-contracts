/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 19:11:09
 * @Description: TSCS 发行的 ERC20 平台货币 Zim, 代币经济模型仍需设计
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC20/ERC20.sol";
import "../interfaces/IZimu.sol";

contract ZMToken is ERC20, IZimu {
    /**
     * @notice TSCS 合约地址
     */
    address public subtitleSystem;
    /**
     * @notice 仅能由 TSCS 调用
     */
    modifier auth() {
        require(msg.sender == subtitleSystem, "ER5");
        _;
    }

    /**
     * @notice 代币总发行量的 20% 用于奖励 TSCS 内的积极行为
     */
    constructor(
        address ss,
        uint256 preMint,
        address tokenOwnerAddress
    ) ERC20("Zimu Token", "ZM") {
        subtitleSystem = ss;
        _mint(tokenOwnerAddress, preMint);
    }

    /**
     * @notice 为用户铸造一定数目的平台币, 当仍剩余奖励代币数时
     * @param to 平台币接收方
     * @param amount 铸造平台币数目
     */
    function mintReward(address to, uint256 amount) public override auth {
        _mint(to, amount);
    }

    /**
     * @notice 为用户铸造一定数目的平台币, 当仍剩余奖励代币数时
     * @param owner 平台币持有方
     * @param amount 销毁平台币数目
     */
    function burnReward(address owner, uint256 amount) public {
        if (msg.sender != subtitleSystem) {
            require(msg.sender == owner, "ER5");
        }
        _burn(owner, amount);
    }

    /**
     * @notice 更改 TSCS 主合约地址
     * @param newSS 新的 TSCS 主合约地址
     */
    function changeTSCS(address newSS) public auth {
        subtitleSystem = newSS;
    }
}
