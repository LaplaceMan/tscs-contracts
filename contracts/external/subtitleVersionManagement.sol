/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-20 15:36:38
 * @Description: 基于 Simhash 实现字幕的版本控制，simhash计算过程在链下进行，以乐观的态度认为大多数用户会诚实上传，当出现不匹配的情况时，进行惩罚
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IST.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IDetectionStrategy.sol";

contract SubtitleVersionManagement {
    /**
     * @notice Murmes 主合约地址
     */
    address public Murmes;
    /**
     * @notice 字幕 ID 与各个版本的映射
     */
    mapping(uint256 => version[]) subtitles;

    /**
     * @notice 字幕对应的结构体，记录每个版本的必要信息
     * @param source 字幕源文件地址
     * @param fingerprint 字幕 Simhash 指纹
     * @param invalid 字幕有效性，默认有效，即使被举报不匹配也不会删除其它两项内容
     */
    struct version {
        string source;
        uint256 fingerprint;
        bool invalid;
    }

    event UpdateSubtitleVersion(
        uint256 subtitleId,
        uint256 fingerprint,
        string source,
        uint256 versionId
    );

    event ReportInvalidVersion(uint256 subtitleId, uint256 versionId);

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 上传/更新字幕版本
     * @param subtitleId ST ID
     * @param fingerprint 新版本字幕 Sinhash 指纹
     * @param source 新版本字幕源地址
     * label SVM1
     */
    function updateSubtitleVersion(
        uint256 subtitleId,
        uint256 fingerprint,
        string memory source
    ) external {
        address st = IMurmes(Murmes).subtitleToken();
        (address maker, , , uint256 version0) = IST(st).getSTBaseInfo(
            subtitleId
        );
        {
            (uint8 state, , , , ) = IMurmes(Murmes).getSubtitleBaseInfo(
                subtitleId
            );
            require(state < 2, "SVM1-1");
        }
        address owner = IST(st).ownerOf(subtitleId);
        require(owner == maker && msg.sender == owner, "SVM1-5");
        require(version0 != fingerprint && fingerprint != 0, "SVM1-1-2");
        address detection = IMurmes(Murmes).detectionStrategy();
        require(
            IDetectionStrategy(detection).afterDetection(version0, fingerprint),
            "SVM1-12"
        );
        if (subtitles[subtitleId].length > 0) {
            for (uint256 i = 0; i < subtitles[subtitleId].length; i++) {
                assert(fingerprint != subtitles[subtitleId][i].fingerprint);
                if (subtitles[subtitleId][i].invalid == false) {
                    require(
                        IDetectionStrategy(detection).afterDetection(
                            fingerprint,
                            subtitles[subtitleId][i].fingerprint
                        ),
                        "SVM1-12-2"
                    );
                }
            }
        }
        subtitles[subtitleId].push(
            version({source: source, fingerprint: fingerprint, invalid: false})
        );
        emit UpdateSubtitleVersion(
            subtitleId,
            fingerprint,
            source,
            subtitles[subtitleId].length
        );
    }

    /**
     * @notice 取消无效的字幕，一般是字幕源文件和 Simhash 指纹不匹配，注意，这将导致往后的已上传版本全部失效
     * @param subtitleId ST ID
     * @param versionId 无效的版本号
     * label SVM2
     */
    function reportInvalidVersion(uint256 subtitleId, uint256 versionId)
        public
    {
        require(IMurmes(Murmes).isOperator(msg.sender), "SVM2-5");
        for (uint256 i = versionId; i < subtitles[subtitleId].length; i++) {
            subtitles[subtitleId][i].invalid = true;
        }
        emit ReportInvalidVersion(subtitleId, versionId);
    }

    /**
     * @notice 当字幕已经被删除时，它的所有版本都应该失效
     * @param subtitleId ST ID
     * label SVM3
     */
    function deleteInvaildSubtitle(uint256 subtitleId) public {
        (uint8 state, , uint256 stateChangeTime, , ) = IMurmes(Murmes)
            .getSubtitleBaseInfo(subtitleId);
        uint256 lockUpTime = IMurmes(Murmes).lockUpTime();
        require(state == 2, "SVM3-1");
        require(block.timestamp > stateChangeTime + 3 * lockUpTime, "SVM3-5");
        if (subtitles[subtitleId].length > 0) {
            for (uint256 i = 0; i < subtitles[subtitleId].length; i++) {
                if (subtitles[subtitleId][i].invalid == false) {
                    subtitles[subtitleId][i].invalid = true;
                    emit ReportInvalidVersion(subtitleId, i);
                }
            }
        }
    }

    /**
     * @notice 获得字幕的指定版本，不支持获得最初版本（应该通过ST合约的tokenURI()获取）
     * @param subtitleId ST ID
     * @param versionId 字幕的版本号
     * @return 特定版本字幕的详细信息
     * label SVM4
     */
    function getSpecifyVersion(uint256 subtitleId, uint256 versionId)
        public
        view
        returns (version memory)
    {
        require(subtitles[subtitleId][versionId].fingerprint != 0, "ER1");
        return subtitles[subtitleId][versionId];
    }

    /**
     * @notice 获得字幕版本总数
     * @param subtitleId ST ID
     * @return 字幕有效的版本数，字幕所有的版本数
     * label SVM5
     */
    function getVersionNumebr(uint256 subtitleId)
        public
        view
        returns (uint256, uint256)
    {
        if (subtitles[subtitleId].length == 0) return (0, 0);
        uint256 validNumber = 0;
        for (uint256 i = 0; i < subtitles[subtitleId].length; i++) {
            if (
                subtitles[subtitleId][i].fingerprint != 0 &&
                subtitles[subtitleId][i].invalid == false
            ) {
                validNumber++;
            }
        }
        return (validNumber, subtitles[subtitleId].length);
    }

    /**
     * @notice 获得最新的有效字幕版本信息
     * @param subtitleId ST ID
     * @return 返回特定字幕最新的有效的版本的详细信息
     * label SVM6
     */
    function getLatestValidVersion(uint256 subtitleId)
        public
        view
        returns (string memory, uint256)
    {
        string memory source;
        uint256 fingerprint;
        for (uint256 i = subtitles[subtitleId].length; i > 0; i--) {
            if (subtitles[subtitleId][i - 1].invalid == false) {
                source = subtitles[subtitleId][i - 1].source;
                fingerprint = subtitles[subtitleId][i - 1].fingerprint;
                break;
            }
        }
        return (source, fingerprint);
    }
}
