// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    mapping(address => bool) opeators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OpeatorsStateChange(address[] indexed opeators, bool indexed state);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier auth() {
        require(msg.sender == _owner || opeators[msg.sender] == true);
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function setOperators(address[] memory operators, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < operators.length; i++) {
            opeators[operators[i]] = state;
        }
        emit OpeatorsStateChange(operators, state);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
