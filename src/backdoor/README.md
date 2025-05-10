# Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.

# Personel Notes
## Understanding the Safe Smart Account System
The Safe Smart Account system is a sophisticated smart contract wallet architecture that provides multi-signature functionality and enhanced security. Let me break down the relationships between the key components:

Core Components
1. Safe Contract
The main implementation contract that contains all the wallet logic
Handles multi-signature verification, transaction execution, and security features
Designed as a singleton that's used by all proxies
2. SafeProxy
A lightweight proxy contract that delegates all calls to the Safe singleton
Stores the address of the singleton in its storage
Each user's wallet is actually a SafeProxy instance pointing to the Safe singleton
Allows for gas-efficient deployment of new wallets
3. SafeProxyFactory
Factory contract that creates new SafeProxy instances
Uses CREATE2 to deploy proxies with deterministic addresses
Can execute initialization code during proxy creation
Emits events when new proxies are created
4. WalletRegistry
Tracks Safe wallets for specific beneficiaries
Implements IProxyCreationCallback interface to be notified when new proxies are created
Validates that wallets are properly configured
Awards tokens to newly registered wallets that meet criteria
Relationship Flow
User Wallet Creation:

A user (or someone on their behalf) calls SafeProxyFactory to create a new SafeProxy
The factory deploys a proxy that points to the Safe singleton
The proxy is initialized with the user as an owner
Wallet Registration:

The SafeProxyFactory can call a callback on WalletRegistry when creating a proxy
WalletRegistry verifies the wallet is properly set up (correct owners, threshold, etc.)
If valid, WalletRegistry records the wallet address for that user and awards tokens
Wallet Usage:

Users interact with their SafeProxy instance
All function calls are delegated to the Safe singleton
The Safe singleton executes the logic but in the context of the proxy's storage
In the Backdoor Challenge Context
In the Backdoor challenge, the WalletRegistry is set up to:

Track a list of beneficiaries (users)
Award 10 tokens to each beneficiary when they register a valid wallet
Enforce specific requirements for wallets (single owner, threshold of 1)
Remove beneficiaries from the list once they've registered a wallet
The challenge involves finding a way to create wallets for all beneficiaries and extract the tokens, likely by exploiting the wallet creation and registration process.

The key insight is that the WalletRegistry's proxyCreated callback is called when a new proxy is created, and it awards tokens if the wallet meets certain criteria. This creates an opportunity to potentially create wallets on behalf of the beneficiaries and extract the tokens.

## wallet owners have several key privileges:

Transaction Execution: Owners can sign and execute transactions from the wallet by providing valid signatures. This is done through the execTransaction function, which requires signatures from enough owners to meet the threshold.

Signature Authority: Owners can sign transactions using various methods:

Standard ECDSA signatures
Contract signatures (EIP-1271)
Pre-approved hash signatures
Hash Approval: Owners can pre-approve transaction hashes using the approveHash function, which allows transactions to be executed later without requiring a new signature.

Owner Management: In a multi-owner setup, owners collectively can add or remove other owners through the OwnerManager functionality that Safe inherits.

Threshold Control: Owners can change the confirmation threshold (number of required signatures) for executing transactions.

Module Management: Owners can add, remove, or interact with modules that extend the wallet's functionality.

Fallback Handler Management: Owners can set or change the fallback handler for the wallet.

Guard Management: Owners can set or change the guard contract that performs pre- and post-transaction checks.

In the specific context of the WalletRegistry challenge, the wallets are set up with a single owner (EXPECTED_OWNERS_COUNT = 1) and a threshold of 1 (EXPECTED_THRESHOLD = 1), meaning the sole owner has complete control over the wallet and can execute any transaction without requiring additional signatures.

The owner essentially has full control over the wallet's assets and configuration, including the ability to transfer tokens, interact with other contracts, and modify the wallet's settings.

## The Vulnerability
The WalletRegistry contract implements the IProxyCreationCallback interface, which means it has a proxyCreated function that gets called when a new proxy is created through the SafeProxyFactory. This function performs several checks to validate the proxy and then transfers tokens to the newly created wallet.

The key issue is that the proxyCreated function doesn't verify who initiated the proxy creation. It only checks:

- If the caller is the expected wallet factory
- If the singleton address matches the expected one
- If the initialization data is valid
- If the wallet owner is a registered beneficiary
### Potential Attack Vector
If you deploy your own proxy using the legitimate SafeProxyFactory and set up the proxy with a registered beneficiary as the owner, you could potentially:

- Control the initialization parameters of the Safe wallet
- Set up the wallet in a way that you can immediately extract the tokens after they're transferred
- Bypass the intended security model where only legitimate beneficiaries should be able to access their wallets

The vulnerability exists because the WalletRegistry assumes that only legitimate beneficiaries will create wallets for themselves, but there's nothing preventing an attacker from creating wallets on behalf of beneficiaries.

Technical Details
The proxyCreated function in WalletRegistry performs these checks:

```solidity
if (msg.sender != walletFactory) {
    revert CallerNotFactory();
}

if (singleton != singletonCopy) {
    revert FakeSingletonCopy();
}
```

These ensure the proxy was created through the legitimate factory, but don't verify who initiated the creation.


```solidity
address walletOwner = owners[0];
if (!beneficiaries[walletOwner]) {
    revert OwnerIsNotABeneficiary();
}
```
This ensures the wallet owner is a registered beneficiary, but doesn't verify that the beneficiary themselves initiated the wallet creation.

This design creates a potential security issue where an attacker could create wallets for beneficiaries and potentially gain control over the funds meant for those beneficiaries.

## I can see why the test is reverting when token is not set as immutable.

The issue is related to how storage variables work during delegate calls. When your attack() function is called via delegate call from the Safe wallet, here's what happens:

The code in attack() runs in the context of the Safe wallet (the caller)
When accessing storage variables like token, it reads from the Safe wallet's storage slots, not from your Attack contract's storage
Since the Safe wallet doesn't have a token variable in the same storage slot, it reads a zero address

When you declare token as immutable, it behaves differently:

Immutable variables are not stored in contract storage
They're embedded directly in the contract's bytecode during deployment
This means they're accessible even during delegate calls, as they're part of the code itself, not the storage

# Personel Notes
## Understanding the Safe Smart Account System
The Safe Smart Account system is a sophisticated smart contract wallet architecture that provides multi-signature functionality and enhanced security. Let me break down the relationships between the key components:

Core Components
1. Safe Contract
The main implementation contract that contains all the wallet logic
Handles multi-signature verification, transaction execution, and security features
Designed as a singleton that's used by all proxies
2. SafeProxy
A lightweight proxy contract that delegates all calls to the Safe singleton
Stores the address of the singleton in its storage
Each user's wallet is actually a SafeProxy instance pointing to the Safe singleton
Allows for gas-efficient deployment of new wallets
3. SafeProxyFactory
Factory contract that creates new SafeProxy instances
Uses CREATE2 to deploy proxies with deterministic addresses
Can execute initialization code during proxy creation
Emits events when new proxies are created
4. WalletRegistry
Tracks Safe wallets for specific beneficiaries
Implements IProxyCreationCallback interface to be notified when new proxies are created
Validates that wallets are properly configured
Awards tokens to newly registered wallets that meet criteria
Relationship Flow
User Wallet Creation:

A user (or someone on their behalf) calls SafeProxyFactory to create a new SafeProxy
The factory deploys a proxy that points to the Safe singleton
The proxy is initialized with the user as an owner
Wallet Registration:

The SafeProxyFactory can call a callback on WalletRegistry when creating a proxy
WalletRegistry verifies the wallet is properly set up (correct owners, threshold, etc.)
If valid, WalletRegistry records the wallet address for that user and awards tokens