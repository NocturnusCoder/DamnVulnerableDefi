# Shards

The Shards NFT marketplace is a permissionless smart contract enabling holders of Damn Valuable NFTs to sell them at any price (expressed in USDC).

These NFTs could be so damn valuable that sellers can offer them in smaller fractions ("shards"). Buyers can buy these shards, represented by an ERC1155 token. The marketplace only pays the seller once the whole NFT is sold.

The marketplace charges sellers a 1% fee in Damn Valuable Tokens (DVT). These can be stored in a secure on-chain vault, which in turn integrates with a DVT staking system.

Somebody is selling one NFT for... wow, a million USDC?

You better dig into that marketplace before the degens find out.

You start with no DVTs. Rescue as much funds as you can in a single transaction, and deposit the assets into the designated recovery account.


## Solution

### Abusing the Marketplace:
The attacker calls fill on the marketplace with a very small amount of shards (NFT_OFFER_SHARDS / 75e21), then immediately cancels the purchase.
The attacker repeats this with another small amount (NFT_OFFER_SHARDS / 11e14), then cancels again.
After each cancel, the attacker receives a refund, but due to a bug in the marketplace’s cancel logic, the refund is greater than the amount paid.

### How the Exploit Works
Marketplace Bug:
The vulnerability lies in the cancel function of the ShardsNFTMarketplace. When cancelling a purchase, the refund calculation uses purchase.shards.mulDivUp(purchase.rate, 1e6). However, the attacker can manipulate the shards and rate values to get a refund that is much larger than the amount initially paid in the fill function.

### Arbitrage on Rate/Amount:
By carefully choosing the want parameter in fill, the attacker ensures that the refund on cancel is much higher than the cost to fill, allowing them to drain the marketplace’s token balance.

### Conclusion
Solution correctly identifies and exploits a refund calculation bug in the cancel function of the ShardsNFTMarketplace. By manipulating the purchase parameters, you are able to drain the marketplace’s token balance and send it to the recovery address in a single transaction, satisfying all challenge requirements. This is a classic example of a precision/rounding error vulnerability in DeFi protocols, where small mathematical imprecisions can be exploited for financial gain.