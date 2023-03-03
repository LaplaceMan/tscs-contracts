/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-05 20:23:26
 * @Description: 权限控制合约
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    address private _multiSig;

    mapping(address => bool) opeators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MutliSigTransferred(address previousMutliSig, address newMutliSig);
    // label O1
    modifier onlyOwner() {
        require(msg.sender == _owner, "O15");
        _;
    }
    // label O2
    modifier auth() {
        require(opeators[msg.sender] == true, "O25");
        _;
    }

    // label O3
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // label O4
    function multiSig() public view returns (address) {
        return _multiSig;
    }

    function isOperator(address operator) public view returns (bool) {
        return opeators[operator];
    }

    // label O5
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "O51");
        _setOwner(newOwner);
    }

    // label O6
    function transferMutliSig(address newMutliSig) external {
        require(msg.sender == _multiSig, "O65");
        require(newMutliSig != address(0), "O61");
        _multiSig = newMutliSig;
    }

    // label O7
    function setOperatorByTool(address old, address replace) internal {
        require(isOperator(msg.sender));
        if (old == address(0)) {
            opeators[replace] = true;
        } else {
            opeators[old] = false;
            opeators[replace] = true;
        }
    }

    // label O8
    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // label O9
    function _setMutliSig(address newMutliSig) internal {
        address oldMutliSig = _multiSig;
        _multiSig = newMutliSig;
        emit MutliSigTransferred(oldMutliSig, newMutliSig);
    }
}
