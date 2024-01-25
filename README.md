# Royalty Hate

This project demonstrates a very simple way to bypass [RariChains](https://rarichain.org/) ["Royalty Mechanism"](https://rari.docs.caldera.dev/royalty#defining-an-nft-sale) with a simple escrow contract.

> [!CAUTION]
> Under no circumstances should you deploy this contract yourself. Please give Rari an opportunity to correct their claim and issues that exist in the model. Further, there is a deliberate bug left in the contract to dissuade you from sending it and deploying whenever you please. This code is offered without guarantee, assurance, nor liability. This should only be used for education purposes.

This contract utilizes standard Solidity and does not break any assumptions held on the blockchain, general or RariChains. Instead, the RariFoundation simply hasn't been completely honest about the state of development nor the "benefits" of the chain they have developed.

> [!WARNING]
> The contract you are browsing is only one of the many ways to prove that their claims are less than truthful and have been said in an attempt to goat creators into entering an ecosystem that does not truly have their best interests at heart.
>
> This is the Foundations response to royalty bypassing:
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
> Given there is no correction of statement, I will go ahead and deploy this contract along with an app to make interaction simple for every user.