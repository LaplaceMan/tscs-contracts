// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IItemNFT.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IDetectionModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function componentGlobal() external view returns (address);

    function getTaskPaymentModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory);
}

contract DetectionModule is IDetectionModule {
    address public Murmes;

    uint256 public distanceThreshold;

    constructor(address ms, uint256 threshold) {
        Murmes = ms;
        distanceThreshold = threshold;
    }

    // Fn 1
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

    // Fn 2
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

    // Fn 3
    function setDistanceThreshold(uint8 newDistanceThreshold) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "DNS15");
        distanceThreshold = newDistanceThreshold;
        emit SystemSetDistanceThreshold(newDistanceThreshold);
    }

    // Fn 4
    function _getHistoryFingerprint(
        uint256 taskId
    ) internal view returns (uint256[] memory) {
        (, uint256[] memory items) = MurmesInterface(Murmes)
            .getTaskPaymentModuleAndItems(taskId);
        uint256[] memory history = new uint256[](items.length);
        address components = MurmesInterface(Murmes).componentGlobal();
        address itemToken = IComponentGlobal(components).itemToken();
        for (uint256 i = 0; i < items.length; i++) {
            history[i] = IItemNFT(itemToken).getItemFingerprint(items[i]);
        }
        return history;
    }

    // ***************** View Functions *****************
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
