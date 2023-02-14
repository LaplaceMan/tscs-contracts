// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILensFeeModuleForMurmes {
    function getTotalIncome(uint256 profileId, uint256 pubId)
        external
        view
        returns (uint256);
}
