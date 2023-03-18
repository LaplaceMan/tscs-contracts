// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IVault.sol";
import "../common/token/ERC20/IERC20.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract Vault is IVault {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice Murmes手续费比例
     */
    uint16 public fee;
    /**
     * @notice Murmes手续费接收地址
     */
    address public feeRecipient;

    constructor(address ms, address recipient) {
        Murmes = ms;
        feeRecipient = recipient;
    }

    /**
     * @notice 提取平台内产生的罚款
     * @param token 欲提取代币的合约地址
     * @param to 代币接收地址
     * @param amount 提取罚款数量
     * Fn 2
     */
    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external override {
        require(MurmesInterface(Murmes).owner() == msg.sender, "V25");
        require(IERC20(token).transfer(to, amount), "V212");
    }

    /**
     * @notice 设置手续费，大于0时开启，等于0时关闭
     * @param newFee 手续费比率，若为1%，应设置为100，因为计算后的值为 100/10000
     * Fn 3
     */
    function setFee(uint16 newFee) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "V35");
        uint16 old = fee;
        fee = newFee;
        emit SystemSetFee(old, newFee);
    }
}
