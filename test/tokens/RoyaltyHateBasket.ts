import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei } from "viem";

describe("RoyaltyHateERC721", function () {
  const deployFixture = async () => {
    const [owner, other] = await hre.viem.getWalletClients();

    const underlying20 = await hre.viem.deployContract("MockERC20", []);
    const underlying721 = await hre.viem.deployContract("MockERC721", []);
    const underlying1155 = await hre.viem.deployContract("MockERC1155", []);
    const hateBasket = await hre.viem.deployContract("RoyaltyHateBasket");

    await underlying20.write.mint([
      owner.account.address,
      100000000000000000000n,
    ]);
    await underlying20.write.approve([
      hateBasket.address,
      100000000000000000000n,
    ]);

    for (let i = 0n; i < 10n; i++) {
      await underlying721.write.mint([owner.account.address, i]);
      if (i % 2n == 0n)
        await underlying721.write.approve([hateBasket.address, i]);
    }

    for (let i = 0n; i < 10n; i++) {
      await underlying1155.write.mint([owner.account.address, i, 1n]);
      if (i % 2n == 0n)
        await underlying1155.write.setApprovalForAll([
          hateBasket.address,
          true,
        ]);
    }

    const publicClient = await hre.viem.getPublicClient();

    return {
      underlying20,
      underlying721,
      underlying1155,
      hateBasket,
      owner,
      other,
      publicClient,
    };
  };

  const makeFixture = async () => {
    const {
      underlying20,
      underlying721,
      underlying1155,
      hateBasket,
      owner,
      ...fixture
    } = await loadFixture(deployFixture);

    await hateBasket.write.make(
      [
        getAddress(owner.account.address),
        {
          erc20: {
            tokenAddresses: [underlying20.address],
            amounts: [100000000000000000000n],
          },
          erc721: {
            tokenAddress: underlying721.address,
            ids: [0n],
          },
          erc1155: {
            tokenAddress: underlying1155.address,
            ids: [0n],
            amounts: [1n],
          },
          value: parseGwei("100"),
        },
      ],
      {
        value: parseGwei("100"),
      }
    );

    return {
      underlying20,
      underlying721,
      underlying1155,
      hateBasket,
      owner,
      ...fixture,
    };
  };

  describe("Deployment", () => {
    it("Should get the right name", async () => {
      const { hateBasket } = await loadFixture(deployFixture);

      expect(await hateBasket.read.name()).to.equal("Royalty Hate: Basket");
    });

    it("Should get the right symbol", async () => {
      const { hateBasket } = await loadFixture(deployFixture);

      expect(await hateBasket.read.symbol()).to.equal("RHBASKET");
    });

    it("Should get the right tokenURI", async () => {
      const { hateBasket } = await loadFixture(makeFixture);

      const base64Uri = await hateBasket.read.tokenURI([0n]);
      const uri = Buffer.from(base64Uri.split(",")[1], "base64").toString(
        "ascii"
      );

      const metadata = {
        name: "Royalty Hate: Basket #0",
        description:
          "A basket of tokens (ETH & ERC20 & ERC1155 & ERC721) bypassing royalty enforcement.",
        image:
          "data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHByZXNlcnZlQXNwZWN0UmF0aW89J3hNaW5ZTWluIG1lZXQnIHZpZXdCb3g9JzAgMCAzNTAgMzUwJz48c3R5bGU+LmJhc2UgeyBmaWxsOiB3aGl0ZTsgZm9udC1mYW1pbHk6IHNlcmlmOyBmb250LXNpemU6IDE0cHg7IH08L3N0eWxlPjxyZWN0IHdpZHRoPScxMDAlJyBoZWlnaHQ9JzEwMCUnIGZpbGw9J2JsYWNrJyAvPjx0ZXh0IHg9JzUwJScgeT0nNTAlJyBkb21pbmFudC1iYXNlbGluZT0nbWlkZGxlJyB0ZXh0LWFuY2hvcj0nbWlkZGxlJyBjbGFzcz0nYmFzZSc+QmFza2V0ICMwPC90ZXh0Pjwvc3ZnPg==",
      };

      expect(JSON.parse(uri)).to.deep.equal(metadata);
    });
  });

  describe("Make", async () => {
    it("Should make single wrapped token", async () => {
      const {
        underlying20,
        underlying721,
        underlying1155,
        hateBasket,
        owner,
        publicClient,
      } = await loadFixture(deployFixture);

      const hash = await hateBasket.write.make(
        [
          getAddress(owner.account.address),
          {
            erc20: {
              tokenAddresses: [underlying20.address],
              amounts: [100000000000000000000n],
            },
            erc721: {
              tokenAddress: underlying721.address,
              ids: [0n],
            },
            erc1155: {
              tokenAddress: underlying1155.address,
              ids: [0n],
              amounts: [1n],
            },
            value: parseGwei("100"),
          },
        ],
        {
          value: parseGwei("100"),
        }
      );
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hateBasket.getEvents.Transfer();
      expect(transferEvents.length).to.equal(1);

      expect(await underlying20.read.balanceOf([hateBasket.address])).to.equal(
        100000000000000000000n
      );
      expect(await underlying721.read.ownerOf([0n])).to.equal(
        getAddress(hateBasket.address)
      );
      expect(
        await underlying1155.read.balanceOf([hateBasket.address, 0n])
      ).to.equal(1n);
      expect(await hateBasket.read.ownerOf([0n])).to.equal(
        getAddress(owner.account.address)
      );
    });

    it("Should fail on unapproved token", async () => {
      const { underlying20, underlying721, underlying1155, hateBasket, owner } =
        await loadFixture(deployFixture);

      await expect(
        hateBasket.write.make(
          [
            getAddress(owner.account.address),
            {
              erc20: {
                tokenAddresses: [underlying20.address],
                amounts: [100000000000000000000n],
              },
              erc721: {
                tokenAddress: underlying721.address,
                ids: [1n],
              },
              erc1155: {
                tokenAddress: underlying1155.address,
                ids: [0n],
                amounts: [1n],
              },
              value: parseGwei("100"),
            },
          ],
          {
            value: parseGwei("100"),
          }
        )
      ).to.be.rejectedWith("NotOwnerNorApproved");
    });
  });

  describe("Take", async () => {
    it("Should take single wrapped token", async () => {
      const { hateBasket, owner, publicClient } =
        await loadFixture(makeFixture);

      const hash = await hateBasket.write.take([
        getAddress(owner.account.address),
        0n,
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hateBasket.getEvents.Transfer();
      expect(transferEvents.length).to.equal(1);
    });

    it("Should fail on unowned token", async () => {
      const { hateBasket, other } = await loadFixture(makeFixture);

      const hateBasketAsOther = await hre.viem.getContractAt(
        "RoyaltyHateBasket",
        hateBasket.address,
        { walletClient: other }
      );

      await expect(
        hateBasketAsOther.write.take([getAddress(other.account.address), 0n])
      ).to.be.rejectedWith("NotOwnerNorApproved");
    });
  });
});
