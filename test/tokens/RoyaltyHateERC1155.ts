import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress } from "viem";

describe("RoyaltyHateERC1155", function () {
  const deployFixture = async () => {
    const [owner, other] = await hre.viem.getWalletClients();

    const underlying1155 = await hre.viem.deployContract("MockERC1155", []);
    const hate1155 = await hre.viem.deployContract("RoyaltyHateERC1155", [
      underlying1155.address,
    ]);

    for (let i = 0n; i < 10n; i++) {
      await underlying1155.write.mint([owner.account.address, i, 1n]);
      if (i % 2n == 0n)
        await underlying1155.write.setApprovalForAll([hate1155.address, true]);
    }

    const publicClient = await hre.viem.getPublicClient();

    return {
      underlying1155,
      hate1155,
      owner,
      other,
      publicClient,
    };
  };

  const makeFixture = async () => {
    const { hate1155, owner, ...fixture } = await loadFixture(deployFixture);

    await hate1155.write.make([
      getAddress(owner.account.address),
      [0n, 2n, 4n, 6n, 8n],
      [1n, 1n, 1n, 1n, 1n],
    ]);

    return {
      hate1155,
      owner,
      ...fixture,
    };
  };

  describe("Deployment", () => {
    it("Should set the right underlying", async () => {
      const { underlying1155, hate1155 } = await loadFixture(deployFixture);

      expect(await hate1155.read.underlying()).to.equal(
        getAddress(underlying1155.address)
      );
    });

    it("Should get the right uri", async () => {
      const { underlying1155, hate1155 } = await loadFixture(deployFixture);

      expect(await hate1155.read.uri([0n])).to.equal(
        await underlying1155.read.uri([0n])
      );
    });
  });

  describe("Make", async () => {
    it("Should make single wrapped token", async () => {
      const { underlying1155, hate1155, owner, publicClient } =
        await loadFixture(deployFixture);

      const hash = await hate1155.write.make([
        getAddress(owner.account.address),
        [0n],
        [1n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate1155.getEvents.TransferSingle();
      expect(transferEvents.length).to.equal(1);

      expect(
        await underlying1155.read.balanceOf([
          getAddress(owner.account.address),
          0n,
        ])
      ).to.equal(0n);
      expect(
        await underlying1155.read.balanceOf([hate1155.address, 0n])
      ).to.equal(1n);
    });

    it("Should make multiple wrapped tokens", async () => {
      const { underlying1155, hate1155, owner, publicClient } =
        await loadFixture(deployFixture);

      const hash = await hate1155.write.make([
        getAddress(owner.account.address),
        [0n, 2n, 4n, 6n, 8n],
        [1n, 1n, 1n, 1n, 1n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate1155.getEvents.TransferSingle();
      expect(transferEvents.length).to.equal(5);

      for (let i = 0n; i < 5n; i++) {
        expect(
          await underlying1155.read.balanceOf([
            getAddress(owner.account.address),
            i * 2n,
          ])
        ).to.equal(0n);
        expect(
          await underlying1155.read.balanceOf([hate1155.address, i * 2n])
        ).to.equal(1n);
      }
    });

    it("Should fail with different size arrays", async () => {
      const { hate1155, owner } = await loadFixture(deployFixture);

      await expect(
        hate1155.write.make([
          getAddress(owner.account.address),
          [0n, 2n, 4n, 6n, 8n],
          [1n, 1n, 1n, 1n],
        ])
      ).to.be.rejectedWith(
        "RoyaltyHateERC1155: tokenIds.length != amounts.length"
      );
    });
  });

  describe("Take", async () => {
    it("Should take single wrapped token", async () => {
      const { hate1155, owner, publicClient } = await loadFixture(makeFixture);

      const hash = await hate1155.write.take([
        getAddress(owner.account.address),
        [0n],
        [1n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate1155.getEvents.TransferSingle();
      expect(transferEvents.length).to.equal(1);
    });

    it("Should take multiple wrapped tokens", async () => {
      const { hate1155, owner, publicClient } = await loadFixture(makeFixture);

      const hash = await hate1155.write.take([
        getAddress(owner.account.address),
        [0n, 2n, 4n, 6n, 8n],
        [1n, 1n, 1n, 1n, 1n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate1155.getEvents.TransferSingle();
      expect(transferEvents.length).to.equal(5);
    });

    it("Should fail on unowned token", async () => {
      const { hate1155, other } = await loadFixture(makeFixture);

      const hate721AsOther = await hre.viem.getContractAt(
        "RoyaltyHateERC1155",
        hate1155.address,
        { walletClient: other }
      );

      await expect(
        hate721AsOther.write.take([
          getAddress(other.account.address),
          [0n],
          [1n],
        ])
      ).to.be.rejectedWith("InsufficientBalance");
    });
  });
});
