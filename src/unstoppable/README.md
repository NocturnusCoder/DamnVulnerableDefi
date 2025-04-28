# Unstoppable

There's a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.

To catch any bugs before going 100% permissionless, the developers decided to run a live beta in testnet. There's a monitoring contract to check liveness of the flashloan feature.

Starting with 10 DVT tokens in balance, show that it's possible to halt the vault. It must stop offering flash loans.


# ERC4626, especially assets vs shares, totalsupply need to be studied!

# Solution: 
To halt the vault, transfer 1 DVT token directly to the vault's address, bypassing the usual deposit mechanism. This will break the vault's accounting logic, as the total assets will no longer match the sum of all user shares.

## anvil addresses when `Unstoppable.s.sol` is deployed in anvil chain:
FeeRecipient and deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DamnValuableToken: 0x5FbDB2315678afecb367f032d93F642f64180aa3
UnstoppableVault: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
UnstoppableMonitor: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707