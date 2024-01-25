import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress } from "viem";

describe("RoyaltyHateERC721", function () {
  const deployFixture = async () => {
    const [owner, other] = await hre.viem.getWalletClients();

    const underlying721 = await hre.viem.deployContract("MockERC721", []);
    const hate721 = await hre.viem.deployContract("RoyaltyHateERC721", [
      underlying721.address,
    ]);

    for (let i = 0n; i < 10n; i++) {
      await underlying721.write.mint([owner.account.address, i]);

      if (i % 2n == 0n) await underlying721.write.approve([hate721.address, i]);
    }

    const publicClient = await hre.viem.getPublicClient();

    return {
      underlying721,
      hate721,
      owner,
      other,
      publicClient,
    };
  };

  const makeFixture = async () => {
    const { hate721, owner, ...fixture } = await loadFixture(deployFixture);

    await hate721.write.make([
      getAddress(owner.account.address),
      [0n, 2n, 4n, 6n, 8n],
    ]);

    return {
      hate721,
      owner,
      ...fixture,
    };
  };

  describe("Deployment", () => {
    it("Should set the right underlying", async () => {
      const { underlying721, hate721 } = await loadFixture(deployFixture);

      expect(await hate721.read.underlying()).to.equal(
        getAddress(underlying721.address)
      );
    });

    it("Should get the right name", async () => {
      const { hate721 } = await loadFixture(deployFixture);

      expect(await hate721.read.name()).to.equal("Royalty Hate: MockERC721");
    });

    it("Should get the right symbol", async () => {
      const { hate721 } = await loadFixture(deployFixture);

      expect(await hate721.read.symbol()).to.equal("RHMOCK");
    });

    it("Should get the right tokenURI", async () => {
      const { underlying721, hate721 } = await loadFixture(deployFixture);

      expect(await hate721.read.tokenURI([0n])).to.equal(
        await underlying721.read.tokenURI([0n])
      );
    });
  });

  describe("Make", async () => {
    it("Should make single wrapped token", async () => {
      const { underlying721, hate721, owner, publicClient } =
        await loadFixture(deployFixture);

      const hash = await hate721.write.make([
        getAddress(owner.account.address),
        [0n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate721.getEvents.Transfer();
      expect(transferEvents.length).to.equal(1);

      expect(await underlying721.read.ownerOf([0n])).to.equal(
        getAddress(hate721.address)
      );
      expect(await hate721.read.ownerOf([0n])).to.equal(
        getAddress(owner.account.address)
      );
    });

    it("Should make multiple wrapped tokens", async () => {
      const { underlying721, hate721, owner, publicClient } =
        await loadFixture(deployFixture);

      const hash = await hate721.write.make([
        getAddress(owner.account.address),
        [0n, 2n, 4n, 6n, 8n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate721.getEvents.Transfer();
      expect(transferEvents.length).to.equal(5);

      for (let i = 0n; i < 5n; i++) {
        expect(await underlying721.read.ownerOf([i * 2n])).to.equal(
          getAddress(hate721.address)
        );
        expect(await hate721.read.ownerOf([i * 2n])).to.equal(
          getAddress(owner.account.address)
        );
      }
    });

    it("Should fail on unapproved token", async () => {
      const { hate721, owner } = await loadFixture(deployFixture);

      await expect(
        hate721.write.make([getAddress(owner.account.address), [1n]])
      ).to.be.rejectedWith("NotOwnerNorApproved");
    });
  });

  describe("Take", async () => {
    it("Should take single wrapped token", async () => {
      const { hate721, owner, publicClient } = await loadFixture(makeFixture);

      const hash = await hate721.write.take([
        getAddress(owner.account.address),
        [0n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate721.getEvents.Transfer();
      expect(transferEvents.length).to.equal(1);
    });

    it("Should take multiple wrapped tokens", async () => {
      const { hate721, owner, publicClient } = await loadFixture(makeFixture);

      const hash = await hate721.write.take([
        getAddress(owner.account.address),
        [0n, 2n, 4n, 6n, 8n],
      ]);
      await publicClient.waitForTransactionReceipt({ hash });

      const transferEvents = await hate721.getEvents.Transfer();
      expect(transferEvents.length).to.equal(5);
    });

    it("Should fail on unowned token", async () => {
      const { hate721, other } = await loadFixture(makeFixture);

      const hate721AsOther = await hre.viem.getContractAt(
        "RoyaltyHateERC721",
        hate721.address,
        { walletClient: other }
      );

      await expect(
        hate721AsOther.write.take([getAddress(other.account.address), [0n]])
      ).to.be.rejectedWith("NotOwnerNorApproved");
    });
  });
});
