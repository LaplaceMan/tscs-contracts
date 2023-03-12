// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";
import "../common/token/ERC20/IERC20.sol";

contract Vault is IVault {
    address public Murmes;

    uint16 public fee;

    uint256 public penalty;

    address public feeRecipient;

    constructor(address ms, address recipient) {
        Murmes = ms;
        feeRecipient = recipient;
    }

    // Fn 1
    modifier auth() {
        require(msg.sender == Murmes, "V15");
        _;
    }

    /**
     * @notice Murmes内罚没的资产
     * @param amount 新增罚没代币数量
     * Fn 2
     */
    function updatePenalty(uint256 amount) public auth {
        penalty += amount;
    }

    /**
     * @notice 提取平台内产生的罚款
     * @param to 代币接收地址
     * @param amount 提取罚款数量
     * Fn 2
     */
    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external {
        require(IMurmes(Murmes).owner() == msg.sender, "V25");
        if (amount > penalty) amount = penalty;
        penalty -= amount;
        require(IERC20(token).transfer(to, amount), "V212");
    }

    /**
     * @notice 设置手续费，大于0时开启，等于0时关闭
     * @param newFee 手续费比率，若为1%，应设置为100，因为计算后的值为 100/10000
     * Fn 3
     */
    function setFee(uint16 newFee) external {
        require(IMurmes(Murmes).owner() == msg.sender, "V35");
        uint16 old = fee;
        fee = newFee;
        emit SystemSetFee(old, newFee);
    }
}
