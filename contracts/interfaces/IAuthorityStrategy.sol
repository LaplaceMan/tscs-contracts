// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IAuthorityStrategy {
    function isOwnApplyAuthority(
        address platform,
        uint256 videoId,
        string memory source,
        address caller,
        uint8 strategy,
        uint256 amount
    ) external;

    function isOwnCreateVideoAuthority(uint256 flag, address caller)
        external
        view;

    function isOwnUpdateViewCountsAuthority(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller
    ) external returns (uint256);
}
