// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IAccessStrategy.sol";

contract AccessStrategy is IAccessStrategy {
    /**
     * @notice 奖惩时计算比率的除数
     */
    uint16 public baseRatio;
    /**
     * @notice TSCS 内用户初始化时的信誉度分数
     */
    uint16 public baseRepution;
    /**
     * @notice 需要质押 ETH 的信誉度分数阈值
     */
    uint8 public depoitThreshold;

    /**
     * @notice 被禁止使用 TSCS 提供服务的信誉度阈值
     */
    uint8 public blacklistThreshold;
    /**
     * @notice 信誉度小于等于 depoitThreshold 时必须最小质押的 ETH 数
     */
    uint256 public minDeposit;
    /**
     * @notice 奖励的代币数量, 此处为 ETH
     */
    uint256 public rewardToken;
    /**
     * @notice 惩罚的代币数量, 此处为 ETH
     */
    uint256 public punishmentToken;
    /**
     * @notice 恶意字幕制作者受到惩罚的倍数, 在计算时除数为 100
     */
    uint8 public multiplier;

    constructor() {
        baseRepution = 100;
        baseRatio = 10 * 100;
        minDeposit = 0.01 ether;
        rewardToken = 0;
        punishmentToken = 0.001 ether;
        multiplier = 150; //表示字幕制作者扣除的信誉度是支持者的 1.5 倍
        blacklistThreshold = 1;
    }

    /**
     * @notice 基于用户当前信誉度, 获得奖励时新增的数值, 信誉度越高获得的奖励越多
     * @param repution 当前信誉度分数
     * @return 可获得的奖励数值
     */
    function _reward(uint256 repution) internal view returns (uint256) {
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
            return (_reward(repution), rewardToken, multiplier);
        } else if (flag == 2) {
            if (repution - _punishment(repution) < depoitThreshold) {
                return (_punishment(repution), punishmentToken, multiplier);
            }
            return (_punishment(repution), 0, multiplier);
        } else {
            return (0, 0, 0);
        }
    }

    function access(uint256 repution, uint256 deposit)
        external
        view
        override
        returns (bool)
    {
        if (
            (repution <= depoitThreshold && deposit <= minDeposit) ||
            repution <= blacklistThreshold
        ) {
            return false;
        } else {
            return true;
        }
    }
}
