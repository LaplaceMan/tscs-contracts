/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-11-21 14:33:27
 * @Description: 管理 TSCS 内质押、手续费相关的资产
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IVT.sol";
import "../interfaces/IZimu.sol";
import "../interfaces/IVault.sol";

contract Vault is IVault {
    /**
     * @notice TSCS内产生的罚款总数（以Zimu计价）
     */
    uint256 public penalty;

    /**
     * @notice 操作员地址, 有权修改该策略中的关键参数
     */
    address public opeator;

    /**
     * @notice TSCS 合约地址
     */
    address public subtitleSystem;

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

    event WithdrawPlatformFee(address to, uint256 amount);

    constructor(address dao, address tscs) {
        opeator = dao;
        subtitleSystem = tscs;
    }

    modifier onlyOwner() {
        require(msg.sender == opeator, "ER5");
        _;
    }

    modifier auth() {
        require(msg.sender == subtitleSystem, "ER5");
        _;
    }

    /**
     * @notice TSCS 内罚没 Zimu 资产
     * @param amount 新增罚没 Zimu 数量
     */
    function changePenalty(uint256 amount) public auth {
        penalty += amount;
    }

    /**
     * @notice 新增手续费，内部功能
     * @param platformId 新增手续费来源平台
     * @param amount 新增手续费数量
     */
    function addFee(uint256 platformId, uint256 amount) public auth {
        feeIncome[platformId] += amount;
    }

    /**
     * @notice 提取平台内产生的罚款
     * @param to Zimu 代币接收地址
     * @param amount 提取罚款数量
     */
    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(penalty >= amount, "ER1");
        penalty -= amount;
        IZimu(token).transferFrom(address(this), to, amount);
        emit WithdrawPenalty(to, amount);
    }

    /**
     * @notice 提取平台内产生的交易费用
     * @param platformIds 平台 IDs
     * @param to VT 代币接收地址
     * @param amounts 提取数量
     */
    function transferVideoPlatformFee(
        address token,
        uint256[] memory platformIds,
        address to,
        uint256[] memory amounts
    ) public onlyOwner {
        for (uint256 i; i < platformIds.length; i++) {
            require(platformIds[i] != 0, "ER1");
            require(feeIncome[platformIds[i]] >= amounts[i], "ER1");
            feeIncome[platformIds[i]] -= amounts[i];
        }
        IVT(token).safeBatchTransferFrom(
            address(this),
            to,
            platformIds,
            amounts,
            ""
        );
        emit WithdrawVideoPlatformFee(to, platformIds, amounts);
    }

    /**
     * @notice 提取平台内产生的交易费用，此功能专用于提取一次性结算时的 Zimu 代币手续费
     * @param token Zimu 代币合约
     * @param to 代币接收地址
     * @param amount 提取代币数量
     */
    function transferPlatformFee(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(feeIncome[0] >= amount, "ER1");
        IZimu(token).transferFrom(address(this), to, amount);
        emit WithdrawPlatformFee(to, amount);
    }

    /**
     * @notice 获得指定平台所拥有的资产数（收费情况）
     * @param platformId 指定 platform 的 ID
     * @return 指定平台所拥有的资产数
     */
    function getFeeIncome(uint256 platformId) public view returns (uint256) {
        return feeIncome[platformId];
    }

    /**
     * @notice 质押代币保存在金库合约中，此功能配合 TSCS 内的提取质押功能一起使用
     * @param token Zimu 代币合约
     * @param to 提币地址
     * @param amount 提币数量
     */
    function withdrawDeposit(
        address token,
        address to,
        uint256 amount
    ) public auth {
        IZimu(token).transferFrom(address(this), to, amount);
    }
}
