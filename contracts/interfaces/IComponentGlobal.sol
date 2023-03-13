// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IComponentGlobal {
    function Murmes() external view returns (address);

    function vault() external view returns (address);

    function access() external view returns (address);

    function version() external view returns (address);

    function platforms() external view returns (address);

    function authority() external view returns (address);

    function arbitration() external view returns (address);

    function itemToken() external view returns (address);

    function platformToken() external view returns (address);

    function defaultDespoitableToken() external view returns (address);

    function lockUpTime() external view returns (uint256);

    event SystemSetDefaultDepositToken(address token);
    event SystemSetComponent(uint8 id, address component);
    event SystemSetLockUpTime(uint256 oldTime, uint256 newTime);
}