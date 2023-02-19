/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-11-21 14:33:27
 * @Description: 管理 Murmes 内质押、手续费相关的资产
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IVT.sol";
import "../interfaces/IZimu.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";

contract Vault is IVault {
    /**
     * @notice 手续费用比率
     */
    uint16 public fee;
    /**
     * @notice TSCS内产生的罚款总数（以Zimu计价）
     */
    uint256 public penalty;
    /**
     * @notice 罚款上限（以Zimu计价）
     */
    uint256 public penaltyUpperLimit;
    /**
     * @notice Murmes 合约地址
     */
    address public Murmes;

    /**
     * @notice 来自于不同平台的手续费收入
     */
    mapping(uint256 => uint256) feeIncome;

    event WithdrawPenalty(address to, uint256 amount);

    event WithdrawVideoPlatformFee(
        address to,
        uint256[] ids,
        uint256[] amounts
    );
    event SystemSetFee(uint16 old, uint16 fee);

    // event WithdrawPlatformFee(address to, uint256 amount);

    constructor(address ms) {
        Murmes = ms;
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
    function changePenalty(uint256 amount) public auth {
        penalty += amount;
    }

    /**
     * @notice 新增手续费，内部功能
     * @param platformId 新增手续费来源平台
     * @param amount 新增手续费数量
     * label V3
     */
    function addFee(uint256 platformId, uint256 amount) public auth {
        feeIncome[platformId] += amount;
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
        emit WithdrawPenalty(to, amount);
    }

    /**
     * @notice 获得指定平台所拥有的资产数（收费情况）
     * @param platformId 指定 platform 的 ID
     * @return 指定平台所拥有的资产数
     * label V5
     */
    function getFeeIncome(uint256 platformId) public view returns (uint256) {
        return feeIncome[platformId];
    }

    /**
     * @notice 质押代币保存在金库合约中，此功能配合 Murmes 内的提取质押功能一起使用
     * @param token Zimu 代币合约
     * @param to 提币地址
     * @param amount 提币数量
     * label V6
     */
    function withdrawDeposit(
        address token,
        address to,
        uint256 amount
    ) external auth {
        require(IZimu(token).transferFrom(address(this), to, amount), "V6-12");
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

    /**
     * @notice 提取平台内产生的交易费用
     * @param platformIds 平台 IDs
     * @param to VT 代币接收地址
     * @param amounts 提取数量
     */
    // function transferVideoPlatformFee(
    //     address token,
    //     uint256[] memory platformIds,
    //     address to,
    //     uint256[] memory amounts
    // ) external {
    //     require(IMurmes(Murmes).isOperator(msg.sender), "ER5");
    //     for (uint256 i; i < platformIds.length; i++) {
    //         require(platformIds[i] != 0, "ER1");
    //         uint256 balance = IVT(token).balanceOf(
    //             address(this),
    //             platformIds[i]
    //         );
    //         require(balance - feeIncome[platformIds[i]] >= amounts[i], "ER1");
    //     }
    //     IVT(token).safeBatchTransferFrom(
    //         address(this),
    //         to,
    //         platformIds,
    //         amounts,
    //         ""
    //     );
    //     emit WithdrawVideoPlatformFee(to, platformIds, amounts);
    // }

    /**
     * @notice 提取平台内产生的交易费用，此功能专用于提取一次性结算时的 Zimu 代币手续费
     * @param token Zimu 代币合约
     * @param to 代币接收地址
     * @param amount 提取代币数量
     */
    // function transferPlatformFee(
    //     address token,
    //     address to,
    //     uint256 amount
    // ) external {
    //     require(IMurmes(Murmes).isOperator(msg.sender), "ER5");
    //     require(feeIncome[0] >= amount, "ER1");
    //     IZimu(token).transferFrom(address(this), to, amount);
    //     emit WithdrawPlatformFee(to, amount);
    // }
}
