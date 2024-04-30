const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("MyERC721EnumerableUpgradeable Contract", function () {
  let token;
  let admin, user1, user2;

  beforeEach(async function () {
    [admin, user1, user2] = await ethers.getSigners();

    const TokenFactory = await ethers.getContractFactory("MyERC721EnumerableUpgradeable");
    token = await upgrades.deployProxy(TokenFactory, [], { initializer: 'initialize' });
  });

  describe("Initialization", function () {
    it("Should set the right owner", async function () {
      expect(await token.owner()).to.equal(admin.address);
    });

    it("Should grant the admin role to the owner", async function () {
      const adminRole = await token.ADMIN_ROLE();
      expect(await token.hasRole(adminRole, admin.address)).to.be.true;
    });
  });

  describe("Minting", function () {
    it("Allows admin to mint a token", async function () {
      await token.connect(admin).mint(user1.address, 1);
      expect(await token.ownerOf(1)).to.equal(user1.address);
    });

    it("Emits an event on minting", async function () {
      await expect(token.connect(admin).mint(user1.address, 1))
        .to.emit(token, 'Minted')
        .withArgs(user1.address, 1);
    });

    it("Prevents non-admins from minting tokens", async function () {
      await expect(token.connect(user1).mint(user1.address, 1))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
    });
  });

  describe("Burning", function () {
    beforeEach(async function () {
      await token.connect(admin).mint(user1.address, 1);
    });

    it("Allows admin to burn a token", async function () {
      await token.connect(admin).burn(user1.address, 1);
      // Update this line to check for the custom error instead of the generic revert message
      await expect(token.ownerOf(1))
        .to.be.revertedWithCustomError(token, 'ERC721NonexistentToken');
    });

    it("Emits an event on burning", async function () {
      await expect(token.connect(admin).burn(user1.address, 1))
        .to.emit(token, 'Burned')
        .withArgs(user1.address, 1);
    });

    it("Prevents non-admins from burning tokens", async function () {
      await expect(token.connect(user2).burn(user1.address, 1))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
    });
  });

  describe("Admin Transfers", function () {
    beforeEach(async function () {
      await token.connect(admin).mint(user1.address, 1);
    });

    it("Allows admin to transfer a token by burning and minting", async function () {
      await token.connect(admin).adminTransfer(user1.address, user2.address, 1);
      expect(await token.ownerOf(1)).to.equal(user2.address);
    });

    it("Emits events on admin transfer", async function () {
      await expect(token.connect(admin).adminTransfer(user1.address, user2.address, 1))
        .to.emit(token, 'AdminTransfer')
        .withArgs(user1.address, user2.address, 1);
    });

    it("Prevents non-admins from performing admin transfers", async function () {
      await expect(token.connect(user1).adminTransfer(user1.address, user2.address, 1))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
    });
  });

  describe("Role Management", function () {
    it("Allows owner to grant admin role", async function () {
      const adminRole = await token.ADMIN_ROLE();
      await token.connect(admin).addAdmin(user1.address);
      expect(await token.hasRole(adminRole, user1.address)).to.be.true;
    });

    it("Allows owner to revoke admin role", async function () {
      const adminRole = await token.ADMIN_ROLE();
      await token.connect(admin).addAdmin(user1.address);
      await token.connect(admin).removeAdmin(user1.address);
      expect(await token.hasRole(adminRole, user1.address)).to.be.false;
    });

    it("Prevents non-owners from managing roles", async function () {
      await expect(token.connect(user1).addAdmin(user2.address))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
      await expect(token.connect(user1).removeAdmin(user2.address))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
    });
  });

  describe("Token Transfer Restrictions", function () {
    beforeEach(async function () {
      // Admin mints a token to user1
      await token.connect(admin).mint(user1.address, 1);
    });

    it("Prevents regular users from transferring tokens", async function () {
      // Attempt to transfer token from user1 to user2 without admin privileges
      await expect(token.connect(user1).transferFrom(user1.address, user2.address, 1))
        .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount');
    });
  });
});
