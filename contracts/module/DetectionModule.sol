// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IItemNFT.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IDetectionModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function componentGlobal() external view returns (address);

    function getTaskSettlementModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory);
}

contract DetectionModule is IDetectionModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 检测阈值
     */
    uint256 public distanceThreshold;

    constructor(address ms, uint256 threshold) {
        Murmes = ms;
        distanceThreshold = threshold;
    }

    /**
     * @notice 设置新的检测阈值
     * @param newDistanceThreshold 新的检测阈值
     */
    function setDistanceThreshold(uint8 newDistanceThreshold) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "DNS15");
        distanceThreshold = newDistanceThreshold;
        emit SetDistanceThreshold(newDistanceThreshold);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 获得特定众包任务下所有Item的指纹值
     * @param taskId 众包任务ID
     * @return 所有Item的指纹值
     */
    function _getHistoryFingerprint(
        uint256 taskId
    ) internal view returns (uint256[] memory) {
        (, uint256[] memory items) = MurmesInterface(Murmes)
            .getTaskSettlementModuleAndItems(taskId);
        uint256[] memory history = new uint256[](items.length);
        address components = MurmesInterface(Murmes).componentGlobal();
        address itemToken = IComponentGlobal(components).itemToken();
        for (uint256 i = 0; i < items.length; i++) {
            history[i] = IItemNFT(itemToken).getItemFingerprint(items[i]);
        }
        return history;
    }

    // ***************** View Functions *****************
    /**
     * @notice 提交Item之前进行的检测
     * @param taskId 众包任务ID
     * @param origin 新上传Item的指纹值
     * @return 是否通过检测
     */
    function detectionInSubmitItem(
        uint256 taskId,
        uint256 origin
    ) external view override returns (bool) {
        uint256[] memory history = _getHistoryFingerprint(taskId);
        for (uint256 i = 0; i < history.length; i++) {
            uint256 distance = hammingDistance(origin, history[i]);
            if (distance <= distanceThreshold) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice 更新Item新版本时进行的检测
     * @param newUpload 新上传Item版本的指纹值
     * @param oldUpload 旧版本Item的指纹值
     * @return 是否通过检测
     */
    function detectionInUpdateItem(
        uint256 newUpload,
        uint256 oldUpload
    ) external view override returns (bool) {
        uint256 distance = hammingDistance(newUpload, oldUpload);
        if (distance <= distanceThreshold) {
            return true;
        }
        return false;
    }

    // 汉明距离计算
    function hammingDistance(
        uint256 a,
        uint256 b
    ) public pure returns (uint256) {
        uint256 c = a ^ b;
        uint256 count = 0;
        while (c != 0) {
            c = c & (c - 1);
            count++;
        }
        return count;
    }
}
