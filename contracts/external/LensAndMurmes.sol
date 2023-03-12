// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract LensAndMurmes {
    address public Murmes;
    address public Lens;

    /**
     * @notice 对Box和Lens资产做映射
     */
    mapping(uint256 => LensItem) boxLensItemMap;

    constructor(address ms, address lens) {
        Lens = lens;
        Murmes = ms;
    }

    struct LensItem {
        uint256 profileId;
        uint256 pubId;
        uint256 income;
    }
}
