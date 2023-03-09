/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-11-21 14:33:27
 * @Description: 管理 Murmes 内质押、手续费相关的资产
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";

contract Vault is IVault {
    /**
     * @notice Murmes 合约地址
     */
    address public Murmes;
    /**
     * @notice 手续费用比率
     */
    uint16 public fee;
    /**
     * @notice TSCS内产生的罚款总数（以Zimu计价）
     */
    uint256 public penalty;

    address public feeRecipient;
    /**
     * @notice 罚款上限（以Zimu计价）
     */
    uint256 public penaltyUpperLimit;

    constructor(address ms, address recipient) {
        Murmes = ms;
        feeRecipient = recipient;
        penaltyUpperLimit = (10**5) * (10**18);
    }

    /**
     * @notice 仅能由主合约 Murmes 调用
     * label V1
     */
    modifier auth() {
        require(msg.sender == Murmes, "V1-5");
        _;
    }

    /**
     * @notice Murmes 内罚没 Zimu 资产
     * @param amount 新增罚没 Zimu 数量
     * label V2
     */
    function updatePenalty(uint256 amount) public auth {
        penalty += amount;
    }

    /**
     * @notice 提取平台内产生的罚款
     * @param to Zimu 代币接收地址
     * @param amount 提取罚款数量
     * label V4
     */
    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external {
        require(
            IMurmes(Murmes).isOperator(msg.sender) ||
                IMurmes(Murmes).owner() == msg.sender,
            "V4-5"
        );
        if (amount > penalty) amount = penalty;
        penalty -= amount;
        require(IZimu(token).transferFrom(address(this), to, amount), "V4-12");
    }

    /**
     * @notice 当罚金数量超过上限时，多余的转移给 Zimu 代币合约，用于社区激励
     * @param token Zimu 代币合约
     * label V7
     */
    function donation(address token) external {
        require(
            IMurmes(Murmes).multiSig() == msg.sender ||
                IMurmes(Murmes).owner() == msg.sender,
            "V7-5"
        );
        require(penalty > penaltyUpperLimit, "V7-5-2");
        uint256 overflow = penalty - penaltyUpperLimit;
        penalty = penaltyUpperLimit;
        require(
            IZimu(token).transferFrom(address(this), token, overflow),
            "V7-12"
        );
    }

    /**
     * @notice 设置手续费，大于0时开启，等于0时关闭
     * @param rate 手续费比率，若为1%，应设置为100，因为计算后的值为 100/BASE_FEE_RATE
     * label V8
     */
    function setFee(uint16 rate) external {
        require(IMurmes(Murmes).owner() == msg.sender, "V8-5");
        uint16 old = fee;
        fee = rate;
        emit SystemSetFee(old, rate);
    }
}
