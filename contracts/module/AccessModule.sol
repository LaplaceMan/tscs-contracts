// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAccessModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AccessModule is IAccessModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 奖惩倍数
     */
    uint8 public multiplier;
    /**
     * @notice 质押代币的基本数目
     */
    uint256 public depositUnit;
    /**
     * @notice 惩罚代币的基本数目
     */
    uint256 public punishmentUnit;

    constructor(address ms) {
        Murmes = ms;
        depositUnit = 32 * 10 ** 18;
        multiplier = 150;
        punishmentUnit = 1 * 10 ** 17;
    }

    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ASM15");
        _;
    }

    /**
     * @notice 设置新的质押代币基本数目
     * @param newDepositUnit 新的质押代币基本数目
     */
    function setDepositUnit(uint256 newDepositUnit) external auth {
        depositUnit = newDepositUnit;
        emit MurmesSetDepositUnit(newDepositUnit);
    }

    /**
     * @notice 设置新的惩罚代币基本数目
     * @param newPunishmentUnit 新的惩罚代币基本数目
     */
    function setPunishmentUnit(uint256 newPunishmentUnit) external auth {
        punishmentUnit = newPunishmentUnit;
        emit MurmesSetPunishmentUnit(newPunishmentUnit);
    }

    /**
     * @notice 设置新的奖惩倍数
     * @param newMultiplier 新的奖惩倍数
     */
    function setMultiplier(uint8 newMultiplier) external auth {
        multiplier = newMultiplier;
        emit MurmesSetMultiplier(newMultiplier);
    }

    // ***************** Internal Functions *****************
    function _sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // ***************** View Functions *****************
    /**
     * @notice 根据当前信誉度分数计算奖励时可额外获得的信誉度分数
     * @param reputation 当前信誉度分数
     * @return 可额外获得的信誉度分数
     */
    function reward(uint256 reputation) public pure returns (uint256) {
        return (reputation / Constant.ACTUAL_REPUTATION);
    }

    /**
     * @notice 根据当前信誉度分数计算惩罚时被扣除的信誉度分数
     * @param reputation 当前信誉度分数
     * @return 被扣除的信誉度分数
     */
    function punishment(uint256 reputation) public pure returns (uint256) {
        return (Constant.MAX_RATE / reputation);
    }

    /**
     * @notice 根据当前信誉度分数计算正常使用Murmes需要质押的代币数目
     * @param reputation 当前信誉度分数
     * @return 需要质押的代币数目
     */
    function deposit(uint256 reputation) public view returns (uint256) {
        if (reputation >= Constant.DEPOSIT_THRESHOLD) {
            return 0;
        } else {
            uint256 baseRate = (Constant.DEPOSIT_THRESHOLD - reputation) / 100;
            return depositUnit * (2 ** baseRate);
        }
    }

    /**
     * @notice 根据当前信誉度分数计算奖惩时信誉度分数和质押代币数目的变化
     * @param reputation 当前信誉度分数
     * @param flag 判断标志，1为奖励，2为惩罚
     * @return 信誉度分数和质押代币数目的变化
     */
    function variation(
        uint256 reputation,
        uint8 flag
    ) external view override returns (uint256, uint256) {
        if (flag == 1) {
            return (reward(reputation), 0);
        } else if (flag == 2) {
            if (reputation < Constant.DEPOSIT_THRESHOLD) {
                uint256 thisPunishment = punishment(reputation);
                return (thisPunishment, thisPunishment * punishmentUnit);
            } else {
                return (punishment(reputation), 0);
            }
        } else {
            return (0, 0);
        }
    }

    /**
     * @notice 根据当前信誉度分数和质押代币数判断用户是否能正常使用Murmes
     * @param reputation 当前信誉度分数
     * @param token 当前质押代币数
     * @return 是否能正常使用Murmes
     */
    function access(
        uint256 reputation,
        int256 token
    ) external view override returns (bool) {
        if (
            (reputation <= Constant.DEPOSIT_THRESHOLD &&
                token <= int256(deposit(reputation))) ||
            reputation <= Constant.BLACKLISTED_THRESHOLD
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 根据质押代币数判断用户是否有参与审核/检测的权限
     * @param token 当前质押代币数
     * @return 是否有参与审核/检测的权限
     */
    function auditable(int256 token) external pure override returns (bool) {
        return (token >= int256(Constant.DEPOSIT_THRESHOLD));
    }

    /**
     * @notice 根据当前信誉度，判断奖惩发生前用户的信誉度
     * @param reputation 当前信誉度
     * @param flag 判断条件，1为发生了奖励，2为进行了惩罚
     * @return 奖惩发生前用户的信誉度
     */
    function lastReputation(
        uint256 reputation,
        uint8 flag
    ) public pure override returns (uint256) {
        uint256 last = 0;
        if (flag == 2) {
            uint256 _4ac = 4 * Constant.MAX_RATE;
            uint256 _sqrtb2_4ac = _sqrt(reputation * reputation + _4ac);
            last = (reputation + _sqrtb2_4ac) / 2;
        } else if (flag == 1) {
            uint256 _base = Constant.ACTUAL_REPUTATION + 1;
            uint256 _up = reputation * Constant.ACTUAL_REPUTATION;
            last = _up / _base;
        }
        return last;
    }
}
