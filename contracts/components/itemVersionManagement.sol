// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IDetectionModule.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IItemVersionManagement.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract ItemVersionManagement is IItemVersionManagement {
    address public Murmes;

    mapping(uint256 => version[]) items;

    event UpdateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string source,
        uint256 versionId
    );
    event ReportInvalidVersion(uint256 itemId, uint256 versionId);

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 上传/更新Item版本
     * @param itemId 唯一标识Item的ID
     * @param fingerprint 新版本Item的指纹值
     * @param source 新版本Item源地址
     * Fn 1
     */
    function updateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string memory source
    ) external {
        address components = IMurmes(Murmes).componentGlobal();
        address itemToken = IComponentGlobal(components).itemToken();
        (address maker, , ) = IItemNFT(itemToken).getItemBaseData(itemId);
        uint256 version0 = IItemNFT(itemToken).getItemFingerprint(itemId);

        {
            DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(itemId);
            require(item.state != DataTypes.ItemState.DELETED, "VM16");
        }
        address owner = IItemNFT(itemToken).ownerOf(itemId);
        require(owner == maker && msg.sender == owner, "VM15");
        require(version0 != fingerprint && fingerprint != 0, "VM11");
        (, , address detection) = IMurmes(Murmes).getItemCustomModuleOfTask(
            itemId
        );
        require(
            IDetectionModule(detection).detectionInUpdateItem(
                version0,
                fingerprint
            ),
            "VM112"
        );
        if (items[itemId].length > 0) {
            for (uint256 i = 0; i < items[itemId].length; i++) {
                assert(fingerprint != items[itemId][i].fingerprint);
                if (items[itemId][i].invalid == false) {
                    require(
                        IDetectionModule(detection).detectionInUpdateItem(
                            fingerprint,
                            items[itemId][i].fingerprint
                        ),
                        "VM113"
                    );
                }
            }
        }
        items[itemId].push(
            version({source: source, fingerprint: fingerprint, invalid: false})
        );
        emit UpdateItemVersion(
            itemId,
            fingerprint,
            source,
            items[itemId].length
        );
    }

    /**
     * @notice 取消无效的Item，一般是Item源文件和指纹不匹配，注意，这将导致往后的已上传版本全部失效
     * @param itemId 唯一标识Item的ID
     * @param versionId 无效的版本号
     * Fn 2
     */
    function reportInvalidVersion(
        uint256 itemId,
        uint256 versionId
    ) public override {
        require(IMurmes(Murmes).isOperator(msg.sender), "VM25");
        for (uint256 i = versionId; i < items[itemId].length; i++) {
            items[itemId][i].invalid = true;
        }
        emit ReportInvalidVersion(itemId, versionId);
    }

    /**
     * @notice 当Item已经被删除时，它的所有版本都应该失效
     * @param itemId 唯一标识Item的ID
     * Fn 3
     */
    function deleteInvaildItem(uint256 itemId) public {
        DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(itemId);
        require(item.state == DataTypes.ItemState.DELETED, "VM31");
        address components = IMurmes(Murmes).componentGlobal();
        uint256 lockUpTime = IComponentGlobal(components).lockUpTime();

        require(
            block.timestamp > item.stateChangeTime + 3 * lockUpTime,
            "VM35"
        );
        if (items[itemId].length > 0) {
            for (uint256 i = 0; i < items[itemId].length; i++) {
                if (items[itemId][i].invalid == false) {
                    items[itemId][i].invalid = true;
                    emit ReportInvalidVersion(itemId, i);
                }
            }
        }
    }

    // ***************** View Functions *****************
    function getSpecifyVersion(
        uint256 itemId,
        uint256 versionId
    ) public view override returns (version memory) {
        require(items[itemId][versionId].fingerprint != 0, "ER1");
        return items[itemId][versionId];
    }

    function getVersionNumebr(
        uint256 itemId
    ) public view override returns (uint256, uint256) {
        if (items[itemId].length == 0) return (0, 0);
        uint256 validNumber = 0;
        for (uint256 i = 0; i < items[itemId].length; i++) {
            if (
                items[itemId][i].fingerprint != 0 &&
                items[itemId][i].invalid == false
            ) {
                validNumber++;
            }
        }
        return (validNumber, items[itemId].length);
    }

    function getLatestValidVersion(
        uint256 itemId
    ) public view override returns (string memory, uint256) {
        string memory source;
        uint256 fingerprint;
        for (uint256 i = items[itemId].length; i > 0; i--) {
            if (items[itemId][i - 1].invalid == false) {
                source = items[itemId][i - 1].source;
                fingerprint = items[itemId][i - 1].fingerprint;
                break;
            }
        }
        return (source, fingerprint);
    }
}
