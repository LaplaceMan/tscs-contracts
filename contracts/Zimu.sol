// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./common/token/ERC20/ERC20.sol";
import "./interfaces/IZimu.sol";

contract ZMToken is ERC20, IZimu {
    address public system;

    modifier auth() {
        require(msg.sender == system);
        _;
    }

    constructor(address ss) ERC20("Zimu Token", "ZM") {
        system = ss;
    }

    function mintReward(address to, uint256 amount) public override auth {
        _mint(to, amount);
    }
}
