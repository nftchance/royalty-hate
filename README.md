# Royalty Hate

This project demonstrates a very simple way to bypass [Rari Chains](https://rarichain.org/) ["Royalty Mechanism"](https://rari.docs.caldera.dev/royalty#defining-an-nft-sale) with a simple escrow contract, or a single token wrapping contract, or even a multi-token wrapping contract.

This contract utilizes standard Solidity and does not break any assumptions held on the blockchain, in general or on Rari Chain. Instead, the Rari Foundation simply hasn't been honest about the state of development nor the "benefits" of the chain they have developed.

If you are looking into the development of a "royalty enforcing" blockchain and cannot find a way to beat these contracts you do not deserve to call your blockchain a "royalty enforcing" chain nor should you pretend that you can build one when interfacing with users.

> [!WARNING]
> The repository you are browsing contains many proof of concepts that visualize the claims are less than truthful and have been said in an attempt to goad creators into entering an ecosystem that does not truly have their best interests at heart.
>
> This is Rari Foundations response to royalty bypassing:
>
> "Regarding people wrapping NFTs to bypass royalties, there is the ability to block or make it harder to interact with wrapped contracts, but that will be up to the DAO to decide, as the chain will be community-governed."
>
> - *janabe | (Rari) Foundation*
>
> As a user of RariChain you are stepping into a heavily-governed chain that puts your funds and collections at risk due to the ineptitude of the developing team.
>
> This is not personal for me. When people lie and make inaccurate claims it MUST be illustrated that they are bad actors attempting to secure revenue for themselves. Countless developers have warned and stressed this reality as can be seen by [an article I released way back in 2022](https://chance.utc24.io/paper/read-write-lease/).
>
> They do not actually care about creators and that can be seen by the viability of not only the contract held within this repository, but by the fact that many other implementations exist.
>
> For now, this will remain active as a proof of concept and example of how NOT to go about claiming you've secured the royalties of creators on your platform. If Rari clarifies to their users that they are falsely claiming benefits (lying) to their creators, then this will not need to be deployed.
>
> Given there is no correction of statement, I will go ahead and deploy this contract along with an app to make interaction simple for every user on the chain.

## How it Works

All models provided operate as public goods. There is no fee associated with the use of the protocol for either the `maker` or `taker`. Now, a `maker` and `taker` can freely and securely transact without the concern of royalties eating away at the value of the economy. The next time someone claims to enforce royalties, this repository will contain every major method to prove them wrong.

> [!CAUTION]
> Under no circumstances should you deploy this contract yourself. Please give Rari an opportunity to correct their claim and issues that exist in the model. This code is offered without guarantee, assurance, or personal liability for actions you choose to take whether it be deployment or interaction. This should only be used for education purposes.

### The Escrow Model

In the initial version of this repository there is a simple escrow contract that is multistep. The flow goes:

1. A `maker` makes an order by depositing the tokens while defining the tokens they will receive from the `taker`.
2. A `taker` fills and order by `taking` the order and depositing the counterparty tokens defined by the `maker`.
3. The `maker` and `taker` can withdraw their assets without being exposed to any royalty mechanism.

### The Single-Wrap Token Model

Following this, I had the realization that you do not even need a multistep escrow implementation if you wrap the tokens that are being traded. Interacting with this version is far simpler and consists of:

1. A `maker` and/or `taker` wraps a token that has royalties appended at zero cost.
2. The assets trade hands.
3. A `maker` and/or `taker` unwraps the token at no cost and without exposure to royalties.

### The Multi-Wrap Token Model

Once again, following the implementation of the single token model it dawned on me that there is an even easier method. Just wrap a basket of assets into a single `ERC721` that of course, does not have royalties. This way, when any party interacts with the token, ownership of multiple assets changes at once without the underlying ownership changing; thus, no royalties to pay!

In practice, this results in an experience of:

1. A `maker` and/or `taker` deposit their assets into the multi-wrapper and receive a single `ERC721`.
2. The basket `ERC721` trades hands.
3. A `maker` and/or `taker` unwraps the token at no cost and without exposure to royalties.
