/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 15:53:06
 * @Description: TSCS 提供的默认访问策略合约
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAccessStrategy.sol";

contract AccessStrategy is IAccessStrategy {
    /**
     * @notice 奖惩时计算比率的除数
     */
    uint16 public baseRatio;
    /**
     * @notice TSCS 内用户初始化时的信誉度分数, 精度为 1 即 100.0
     */
    uint16 constant baseRepution = 100;
    /**
     * @notice 需要质押 Zimu 的信誉度分数阈值
     */
    uint8 public depoitThreshold;

    /**
     * @notice 被禁止使用 TSCS 提供服务的信誉度阈值
     */
    uint8 public blacklistThreshold;
    /**
     * @notice 信誉度小于等于 depoitThreshold 时必须最小质押的 Zimu 数
     */
    uint256 public minDeposit;
    /**
     * @notice 奖励的代币数量, 此处为 Zimu
     */
    uint256 public rewardToken;
    /**
     * @notice 惩罚的代币数量, 此处为 Zimu
     */
    uint256 public punishmentToken;
    /**
     * @notice 恶意字幕制作者受到惩罚的倍数, 在计算时除数为 100
     */
    uint8 public multiplier;

    /**
     * @notice 操作员地址, 有权修改该策略中的关键参数
     */
    address public opeator;

    event SystemSetBaseRatio(uint16 newBaseRatio);
    event SystemSetDepoitThreshold(uint8 newDepoitThreshold);
    event SystemSetBlacklistThreshold(uint8 newBlacklistThreshold);
    event SystemSetMinDeposit(uint256 newMinDeposit);
    event SystemSetRewardToken(uint256 newRewardToken);
    event SystemSetPunishmentToken(uint256 newPunishmentToken);
    event SystemSetMultiplier(uint8 newMultiplier);
    event SystemChangeOpeator(address newOpeator);

    modifier onlyOwner() {
        require(msg.sender == opeator, "ER5");
        _;
    }

    constructor(address dao) {
        baseRatio = 10 * 1000;
        minDeposit = 10**18;
        rewardToken = 0;
        punishmentToken = 1**17;
        multiplier = 150; //表示字幕制作者扣除的信誉度是支持者的 1.5 倍
        blacklistThreshold = 1;
        opeator = dao;
    }

    /**
     * @notice 基于用户当前信誉度, 获得奖励时新增的数值, 信誉度越高获得的奖励越多
     * @param repution 当前信誉度分数
     * @return 可获得的奖励数值
     */
    function _reward(uint256 repution) internal pure returns (uint256) {
        return (repution / baseRepution);
    }

    /**
     * @notice 基于用户当前信誉度, 获得惩罚时扣除的数值, 信誉度越低惩罚的力度越大
     * @param repution 当前信誉度分数
     * @return 被扣除的惩罚数值
     */
    function _punishment(uint256 repution) internal view returns (uint256) {
        return (baseRatio / repution);
    }

    /**
     * @notice 根据用户当前信誉度分数获得奖励或惩罚的力度
     * @param repution 用户当前信誉度分数
     * @param flag 奖惩标志位, 1 为奖励, 2 为惩罚
     * @return 奖励/扣除信誉度分数, 奖励/扣除 Zimu 数目, 字幕制作者受到的奖励/惩罚力度放大倍数
     */
    function spread(uint256 repution, uint8 flag)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint8
        )
    {
        if (flag == 1) {
            //rewardToken 为 0, 代币奖励策略仍在设计中
            return (_reward(repution), rewardToken, multiplier);
        } else if (flag == 2) {
            //当信誉度分数低于 depoitThreshold 时, 每次惩罚都会扣除 Zimu, 此处对用户的区分逻辑为: （优秀）正常、危险、恶意
            if (repution - _punishment(repution) < depoitThreshold) {
                return (_punishment(repution), punishmentToken, multiplier);
            }
            return (_punishment(repution), 0, multiplier);
        } else {
            return (0, 0, 0);
        }
    }

    /**
     * @notice 根据信誉度分数和质押 Zimu 数判断当前用户是否有使用 TSCS 提供的服务的资格
     * @param repution 用户当前信誉度分数
     * @param deposit 用户当前质押 Zimu 数
     * @return 返回 false 表示用户被禁止使用 TSCS 提供的服务, 反之可以继续使用
     */
    function access(uint256 repution, int256 deposit)
        external
        view
        override
        returns (bool)
    {
        if (
            (repution <= depoitThreshold && deposit <= int256(minDeposit)) ||
            repution <= blacklistThreshold
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 以下均为对策略内关键参数的修改功能, 一般将 opeator 设置为 DAO 合约
     */
    function setBaseRatio(uint16 newRatio) external onlyOwner {
        baseRatio = newRatio;
        emit SystemSetBaseRatio(newRatio);
    }

    function setDepoitThreshold(uint8 newDepoitThreshold) external onlyOwner {
        depoitThreshold = newDepoitThreshold;
        emit SystemSetDepoitThreshold(newDepoitThreshold);
    }

    function setBlacklistThreshold(uint8 newBlacklistThreshold)
        external
        onlyOwner
    {
        blacklistThreshold = newBlacklistThreshold;
        emit SystemSetBlacklistThreshold(newBlacklistThreshold);
    }

    function setMinDeposit(uint256 newMinDeposit) external onlyOwner {
        minDeposit = newMinDeposit;
        emit SystemSetMinDeposit(newMinDeposit);
    }

    function setRewardToken(uint256 newRewardToken) external onlyOwner {
        rewardToken = newRewardToken;
        emit SystemSetRewardToken(newRewardToken);
    }

    function setPunishmentToken(uint256 newPunishmentToken) external onlyOwner {
        punishmentToken = newPunishmentToken;
        emit SystemSetPunishmentToken(newPunishmentToken);
    }

    function setMultiplier(uint8 newMultiplier) external onlyOwner {
        multiplier = newMultiplier;
        emit SystemSetMultiplier(newMultiplier);
    }

    function changeOpeator(address newOpeator) external onlyOwner {
        opeator = newOpeator;
        emit SystemChangeOpeator(newOpeator);
    }
}
