// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";
import { ethers } from "hardhat";

import type { 
  Blacklist, Blacklist__factory, 
  Warrior, Warrior__factory 
} from "../src/types";

describe("Warrior", function () {
  before(async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.admin = signers[0];
    this.user = signers[1];
    this.blacklisted = signers[2];

    const blacklistFactory = <Blacklist__factory>await ethers.getContractFactory("Blacklist");
    this.blacklist = <Blacklist>await blacklistFactory.deploy();
    await this.blacklist.add([this.blacklisted.address]);

    const heroFactory = <Warrior__factory>await ethers.getContractFactory("Warrior");
    this.hero = <Warrior>await heroFactory.deploy();
    await this.hero.deployed();
    await this.hero.initialize();
    await this.hero.setMinter(this.admin.address, true);
    await this.hero.setBlacklist(this.blacklist.address);
  });

  describe("mint", function () {
    it("mint hero", async function () {
      await this.hero.mint(this.admin.address, 0);
      expect(await this.hero.ownerOf(1)).to.eq(this.admin.address);
    });
  });

  describe("transferFrom", function () {
    it("should be reverted if spender is blocked", async function () {
      await this.hero.mint(this.admin.address, 0); // id = 1

      await expect(this.hero.approve(this.blacklisted.address, 1)).to.be.revertedWith("Warrior: Blocked operator");

      await expect(
        this.hero.connect(this.blacklisted).transferFrom(this.admin.address, this.user.address, 1),
      ).to.be.revertedWith("Warrior: Blocked operator");
    });

    it("should be ok if spender is not blocked", async function () {
      await this.hero.mint(this.admin.address, 0); // id = 1
      await this.hero.approve(this.user.address, 1);
      await this.hero.connect(this.user).transferFrom(this.admin.address, this.blacklisted.address, 1);

      expect(await this.hero.ownerOf(1)).to.eq(this.blacklisted.address);
    });
  });
});
