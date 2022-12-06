// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC20/IERC20.sol";

interface IZimu is IERC20 {
    function Murmes() external view returns (address);

    function mintReward(address to, uint256 amount) external;
}
