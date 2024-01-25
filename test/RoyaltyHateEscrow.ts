import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei, zeroAddress } from "viem";

enum RoyaltyHateState {
  made,
  cancelled,
  taking,
  taken,
}

describe("RoyaltyHateEscrow", function () {
  const deployFixture = async () => {
    const [owner, other] = await hre.viem.getWalletClients();

    const underlying20 = await hre.viem.deployContract("MockERC20", []);
    const underlying721 = await hre.viem.deployContract("MockERC721", []);
    const underlying1155 = await hre.viem.deployContract("MockERC1155", []);
    const hateEscrow = await hre.viem.deployContract("RoyaltyHateEscrow");

    await underlying20.write.mint([
      owner.account.address,
      100000000000000000000n,
    ]);
    await underlying20.write.approve([
      hateEscrow.address,
      100000000000000000000n,
    ]);

    const underlying721AsOther = await hre.viem.getContractAt(
      "MockERC721",
      underlying721.address,
      { walletClient: other }
    );

    for (let i = 0n; i < 10n; i++) {
      await underlying721.write.mint([owner.account.address, i]);
      await underlying721.write.mint([other.account.address, 10n + i]);
      if (i % 2n == 0n) {
        await underlying721.write.approve([hateEscrow.address, i]);
        await underlying721AsOther.write.approve([hateEscrow.address, 10n + i]);
      }
    }

    for (let i = 0n; i < 10n; i++) {
      await underlying1155.write.mint([owner.account.address, i, 1n]);
      await underlying1155.write.mint([other.account.address, 10n + i, 1n]);
    }

    await underlying1155.write.setApprovalForAll([hateEscrow.address, true]);
    const underlying1155AsOther = await hre.viem.getContractAt(
      "MockERC1155",
      underlying1155.address,
      { walletClient: other }
    );
    await underlying1155AsOther.write.setApprovalForAll([
      hateEscrow.address,
      true,
    ]);

    const publicClient = await hre.viem.getPublicClient();

    const expiration = (await time.latest()) + 1000;

    const mockOrder = {
      taker: zeroAddress,
      expiration,
      nonce: 0,
      state: RoyaltyHateState.made,
      makerDetails: {
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
        value: 0n,
      },
      takerDetails: {
        erc20: {
          tokenAddresses: [],
          amounts: [],
        },
        erc721: {
          tokenAddress: underlying721.address,
          ids: [12n],
        },
        erc1155: {
          tokenAddress: zeroAddress,
          ids: [],
          amounts: [],
        },
        value: parseGwei("100"),
      },
      recoveryDetails: {
        maker: zeroAddress,
        taker: zeroAddress,
      },
    };

    return {
      underlying20,
      underlying721,
      underlying1155,
      hateEscrow,
      owner,
      other,
      publicClient,
      mockOrder,
      expiration,
    };
  };

  const makeFixture = async () => {
    const {
      underlying20,
      underlying721,
      underlying1155,
      hateEscrow,
      mockOrder,
      ...fixture
    } = await loadFixture(deployFixture);

    await hateEscrow.write.make([mockOrder]);

    return {
      underlying20,
      underlying721,
      underlying1155,
      hateEscrow,
      mockOrder,
      ...fixture,
    };
  };

  const takingFixture = async () => {
    const { hateEscrow, owner, other, ...fixture } =
      await loadFixture(makeFixture);

    const hateEscrowAsOther = await hre.viem.getContractAt(
      "RoyaltyHateEscrow",
      hateEscrow.address,
      { walletClient: other }
    );

    const hash = await hateEscrowAsOther.write.taking(
      [getAddress(owner.account.address), 0],
      {
        value: parseGwei("100"),
      }
    );

    return {
      hateEscrow,
      owner,
      other,
      hash,
      ...fixture,
    };
  };

  describe("Deployment", () => {
    it("Should set the right owner", async () => {
      const { hateEscrow, owner } = await loadFixture(deployFixture);

      expect(await hateEscrow.read.owner()).to.equal(
        getAddress(owner.account.address)
      );
    });

    it("Should set the book as open", async () => {
      const { hateEscrow } = await loadFixture(deployFixture);

      expect(await hateEscrow.read.open()).to.equal(true);
    });
  });

  describe("Make", async () => {
    it("Should make an order", async () => {
      const { hateEscrow, publicClient, mockOrder } =
        await loadFixture(deployFixture);

      const hash = await hateEscrow.write.make([mockOrder]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hateEscrow.getEvents.MakeRoyaltyHate();
      expect(transferEvents.length).to.equal(1);
    });

    it("Should fail on unapproved token", async () => {
      const {
        underlying20,
        underlying721,
        underlying1155,
        hateEscrow,
        expiration,
      } = await loadFixture(deployFixture);

      await expect(
        hateEscrow.write.make([
          {
            taker: zeroAddress,
            expiration,
            nonce: 0,
            state: RoyaltyHateState.made,
            makerDetails: {
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
              value: 0n,
            },
            takerDetails: {
              erc20: {
                tokenAddresses: [],
                amounts: [],
              },
              erc721: {
                tokenAddress: underlying721.address,
                ids: [12n],
              },
              erc1155: {
                tokenAddress: zeroAddress,
                ids: [],
                amounts: [],
              },
              value: parseGwei("100"),
            },
            recoveryDetails: {
              maker: zeroAddress,
              taker: zeroAddress,
            },
          },
        ])
      ).to.be.rejectedWith("NotOwnerNorApproved");
    });
  });

  describe("Cancel", async () => {
    it("Should cancel active order", async () => {
      const { hateEscrow, owner } = await loadFixture(makeFixture);

      await hateEscrow.write.cancel([0]);

      const details = await hateEscrow.read.details([
        getAddress(owner.account.address),
        0,
      ]);

      expect(details.state).to.equal(RoyaltyHateState.cancelled);
    });
  });

  describe("Taking", async () => {
    it("Should successfully signal taking intent", async () => {
      const { hateEscrow, owner, other, publicClient } =
        await loadFixture(makeFixture);

      const hateEscrowAsOther = await hre.viem.getContractAt(
        "RoyaltyHateEscrow",
        hateEscrow.address,
        { walletClient: other }
      );

      const hash = await hateEscrowAsOther.write.taking(
        [getAddress(owner.account.address), 0],
        {
          value: parseGwei("100"),
        }
      );
      await publicClient.waitForTransactionReceipt({ hash });

      const TakingRoyaltyHateEvents =
        await hateEscrow.getEvents.TakingRoyaltyHate();
      expect(TakingRoyaltyHateEvents.length).to.equal(1);

      const details = await hateEscrowAsOther.read.details([
        getAddress(owner.account.address),
        0,
      ]);

      expect(details.state).to.equal(RoyaltyHateState.taking);
    });
  });

  describe("Take", async () => {
    it("Should take the swapped assets from the contract", async () => {
      const { hateEscrow, owner, publicClient } =
        await loadFixture(takingFixture);

      const hash = await hateEscrow.write.take([
        getAddress(owner.account.address),
        0,
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hateEscrow.getEvents.TakeRoyaltyHate();
      expect(transferEvents.length).to.equal(1);
    });
  });

  describe("Recover", async () => {
    it("Should recover the assets being taken after expiration", async () => {
      const { hateEscrow, owner, other } = await loadFixture(takingFixture);

      await time.increase(2000);

      await hateEscrow.write.recover([getAddress(owner.account.address), 0]);
      await expect(
        hateEscrow.write.recover([getAddress(owner.account.address), 0])
      ).to.be.rejectedWith(
        "RoyaltyHate: hateRecoveryDetails.maker != address(0)"
      );

      const hateEscrowAsOther = await hre.viem.getContractAt(
        "RoyaltyHateEscrow",
        hateEscrow.address,
        { walletClient: other }
      );

      await hateEscrowAsOther.write.recover([
        getAddress(owner.account.address),
        0,
      ]);
      await expect(
        hateEscrowAsOther.write.recover([getAddress(owner.account.address), 0])
      ).to.be.rejectedWith(
        "RoyaltyHate: hateRecoveryDetails.taker != address(0)"
      );
    });
  });
});
