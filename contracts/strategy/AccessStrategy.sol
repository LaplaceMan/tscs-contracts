/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 15:53:06
 * @Description: Murmes 提供的默认访问策略合约
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAccessStrategy.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AccessStrategy is IAccessStrategy {
    /**
     * @notice 奖惩时计算比率的除数
     */
    uint32 constant BASE_RATIO = 100000;
    /**
     * @notice Murmes 内用户初始化时的信誉度分数, 精度为 1 即 100.0
     */
    uint16 constant BASE_REPUTATION = 100;
    /**
     * @notice 需要质押 Zimu 的信誉度分数阈值
     */
    uint16 public depositThreshold;

    /**
     * @notice 被禁止使用 Murmes 提供服务的信誉度阈值
     */
    uint8 public blacklistThreshold;
    /**
     * @notice 恶意字幕制作者受到惩罚的倍数, 在计算时除数为 100
     */
    uint8 public multiplier;
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
     * @notice 协议主合约地址
     */
    address public immutable Murmes;

    event SystemSetBaseRatio(uint16 newBaseRatio);
    event SystemSetDepoitThreshold(uint8 newDepoitThreshold);
    event SystemSetBlacklistThreshold(uint8 newBlacklistThreshold);
    event SystemSetMinDeposit(uint256 newMinDeposit);
    event SystemSetRewardToken(uint256 newRewardToken);
    event SystemSetPunishmentToken(uint256 newPunishmentToken);
    event SystemSetMultiplier(uint8 newMultiplier);
    // label ASS1
    modifier onlyOwner() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ASS1-5");
        _;
    }

    constructor(address ms) {
        minDeposit = 32 * 10**18;
        rewardToken = 1 * 10**14;
        punishmentToken = 1 * 10**17;
        multiplier = 150; //表示字幕制作者扣除的信誉度是支持者的 1.5 倍
        blacklistThreshold = 1;
        depositThreshold = 600; //60.0
        Murmes = ms;
    }

    /**
     * @notice 基于用户当前信誉度, 获得奖励时新增的数值, 信誉度越高获得的奖励越多
     * @param reputation 当前信誉度分数
     * @return 可获得的奖励数值
     * label ASS2
     */
    function reward(uint256 reputation) public pure returns (uint256) {
        return (reputation / BASE_REPUTATION);
    }

    /**
     * @notice 基于用户当前信誉度, 获得惩罚时扣除的数值, 信誉度越低惩罚的力度越大
     * @param reputation 当前信誉度分数
     * @return 被扣除的惩罚数值
     * label ASS3
     */
    function punishment(uint256 reputation) public pure returns (uint256) {
        return (BASE_RATIO / reputation);
    }

    /**
     * @notice 当信誉度过低时，需要质押一定数目的 Zimu 代币，且信誉度越低需要质押的数目越多
     * @param reputation 用户当前信誉度分数
     * @return 应（最少）质押 Zimu 代币数
     * label ASS4
     */
    function deposit(uint256 reputation) public view returns (uint256) {
        if (reputation > depositThreshold) {
            return 0;
        } else {
            uint256 baseRate = (depositThreshold - reputation) / 100;
            return minDeposit * (2**baseRate);
        }
    }

    /**
     * @notice 根据用户当前信誉度分数获得奖励或惩罚的力度
     * @param reputation 用户当前信誉度分数
     * @param flag 奖惩标志位, 1 为奖励, 2 为惩罚
     * @return 奖励/扣除信誉度分数, 奖励/扣除 Zimu 数目, 字幕制作者受到的奖励/惩罚力度放大倍数
     * label ASS5
     */
    function spread(uint256 reputation, uint8 flag)
        external
        view
        override
        returns (uint256, uint256)
    {
        if (flag == 1) {
            uint256 thisReward = reward(reputation);
            return (thisReward, thisReward * rewardToken);
        } else if (flag == 2) {
            // 当信誉度分数低于 depoitThreshold 时, 每次惩罚都会扣除 Zimu, 此处对用户的区分逻辑为: （优秀）正常、危险、恶意
            if (reputation < depositThreshold) {
                uint256 thisPunishment = punishment(reputation);
                return (thisPunishment, thisPunishment * punishmentToken);
            } else {
                return (punishment(reputation), 0);
            }
        } else {
            return (0, 0);
        }
    }

    /**
     * @notice 根据信誉度分数和质押 Zimu 数判断当前用户是否有使用 Murmes 提供的服务的资格
     * @param reputation 用户当前信誉度分数
     * @param deposit_ 用户当前质押 Zimu 数
     * @return 返回 false 表示用户被禁止使用 Murmes 提供的服务, 反之可以继续使用
     * label ASS6
     */
    function access(uint256 reputation, int256 deposit_)
        external
        view
        override
        returns (bool)
    {
        if (
            (reputation <= depositThreshold &&
                deposit_ <= int256(deposit(reputation))) ||
            reputation <= blacklistThreshold
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 在用户状态非危险的情况下，判断是否有审核/评价权限
     * @param deposit_ 质押的Zimu代币数
     * @return 是否有资格
     * label ASS7
     */
    function auditable(int256 deposit_) external view override returns (bool) {
        if (deposit_ < int256(minDeposit)) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 求平方根
     * label ASS8
     */
    function _sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @notice 根据当前信誉度计算上一个状态的信誉度
     * @param reputation 当前信誉度分数
     * @param flag 信誉度变化的事件
     * @return 上一个状态（事件发生前）的信誉度
     * label ASS9
     */
    function lastReputation(uint256 reputation, uint8 flag)
        public
        pure
        returns (uint256)
    {
        uint256 last = 0;
        if (flag == 2) {
            uint256 _4ac = 4 * BASE_RATIO;
            uint256 _sqrtb2_4ac = _sqrt(reputation * reputation - _4ac);
            last = reputation + _sqrtb2_4ac / 2;
        } else if (flag == 1) {
            uint256 _base = BASE_REPUTATION + 1;
            uint256 _up = reputation * BASE_REPUTATION;
            last = _up / _base;
        }
        return last;
    }

    /**
     * @notice 以下均为对策略内关键参数的修改功能, 一般将 opeator 设置为 DAO 合约
     * label ASS10
     */
    function setDepoitThreshold(uint8 newDepoitThreshold) external onlyOwner {
        depositThreshold = newDepoitThreshold;
        emit SystemSetDepoitThreshold(newDepoitThreshold);
    }

    // label ASS11
    function setBlacklistThreshold(uint8 newBlacklistThreshold)
        external
        onlyOwner
    {
        blacklistThreshold = newBlacklistThreshold;
        emit SystemSetBlacklistThreshold(newBlacklistThreshold);
    }

    // label ASS12
    function setMinDeposit(uint256 newMinDeposit) external onlyOwner {
        minDeposit = newMinDeposit;
        emit SystemSetMinDeposit(newMinDeposit);
    }

    // label ASS13
    function setRewardToken(uint256 newRewardToken) external onlyOwner {
        rewardToken = newRewardToken;
        emit SystemSetRewardToken(newRewardToken);
    }

    // label ASS14
    function setPunishmentToken(uint256 newPunishmentToken) external onlyOwner {
        punishmentToken = newPunishmentToken;
        emit SystemSetPunishmentToken(newPunishmentToken);
    }

    // label ASS15
    function setMultiplier(uint8 newMultiplier) external onlyOwner {
        multiplier = newMultiplier;
        emit SystemSetMultiplier(newMultiplier);
    }
}
