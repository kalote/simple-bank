import { expect } from "chai";
import { ethers } from "hardhat";
import { SimpleBank } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const DEFAULT_CURRENCIES = ["EUR", "USD", "GBP"];

describe("SimpleBank", () => {
  let SimpleBank: SimpleBank;
  let owner: SignerWithAddress;
  let client1: SignerWithAddress;

  beforeEach(async () => {
    [owner, client1] = await ethers.getSigners();
    const SimpleBankFactory = await ethers.getContractFactory("SimpleBank");
    SimpleBank = await SimpleBankFactory.deploy();
    await SimpleBank.deployed();
  });

  describe("When the contract is initialized", () => {
    it("should have an owner", async () => {
      // arrange
      const ownerAddress = owner.address;
      // act
      const expected = await SimpleBank.owner();
      // assert
      expect(expected).to.eq(ownerAddress);
    });

    it("should have a list of default currencies", async () => {
      // arrange
      const currLength = DEFAULT_CURRENCIES.length;
      for (let i = 0; i < currLength; i++) {
        // act
        const currency = await SimpleBank.currencies(i);
        // assert
        expect(currency).to.eq(DEFAULT_CURRENCIES[i]);
      }
    });

    it("should have the owner registered as a client", async () => {
      // arrange
      const ownerAddress = owner.address;
      // act
      const expected = await SimpleBank.registered(ownerAddress);
      // assert
      expect(expected).to.eq(true);
    });
  });

  describe("When the user is not registered", () => {
    it("should throw when interacting with the bank", async () => {
      // arrange
      const amount = 10;
      // assert
      await expect(
        SimpleBank.connect(client1).deposit("EUR", amount)
      ).to.revertedWith("Only registered clients can use this function");
    });
  });
});
