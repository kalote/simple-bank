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

  describe("When the user is not a registered client", () => {
    it("should throw when trying to deposit", async () => {
      // arrange
      const amount = 10;
      // act
      const deposited = async () =>
        SimpleBank.connect(client1).deposit("EUR", amount);
      // assert
      await expect(deposited()).to.revertedWith(
        "Only registered clients can use this function"
      );
    });
  });

  describe("When the user is not the owner", () => {
    it("should throw when trying to add a new currency", async () => {
      // arrange
      const currencyCode = "YEN";
      // act
      const added = async () =>
        SimpleBank.connect(client1).addNewCurrency(currencyCode);
      // assert
      await expect(added()).to.revertedWith("Only owner can use this function");
    });
  });

  describe("When the currency doesn't exists", () => {
    it("should throw when trying to deposit", async () => {
      // arrange
      const amount = 10;
      // act
      const deposited = async () => SimpleBank.deposit("YEN", amount);
      // assert
      await expect(deposited()).to.revertedWith("Currency not available");
    });
  });

  describe("When the client uses the bank", () => {
    it("should register & check registered", async () => {
      // arrange
      const clientAddress = client1.address;
      // act
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const expected = await SimpleBank.registered(clientAddress);
      // assert
      expect(expected).to.eq(true);
    });
    it("should register & deposit & check balance", async () => {
      // arrange
      const amount = 20;
      // act
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const deposit = await SimpleBank.connect(client1).deposit("EUR", amount);
      await deposit.wait();
      const balance = await SimpleBank.connect(client1).getBalance("EUR");
      // assert
      expect(balance).to.eq(amount);
    });
    it("should register & deposit & withdraw & check balance", async () => {
      // arrange
      const amountToDeposit = 100;
      const amountToWithdraw = 20;
      // act
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const deposit = await SimpleBank.connect(client1).deposit(
        "USD",
        amountToDeposit
      );
      await deposit.wait();
      const withdraw = await SimpleBank.connect(client1).withdraw(
        "USD",
        amountToWithdraw
      );
      await withdraw.wait();
      const balance = await SimpleBank.connect(client1).getBalance("USD");
      // assert
      expect(balance).to.eq(amountToDeposit - amountToWithdraw);
    });
  });

  describe("When the client uses multiple currencies", () => {
    it("should register & deposit GBP / EUR & withdraw EUR & check balance GBP / EUR / USD", async () => {
      // arrange
      const amountToDepositGBP = 100;
      const amountToDepositEUR = 100;
      const amountToDepositUSD = 0;
      const amountToWithdrawEUR = 20;
      // act
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const depositGBP = await SimpleBank.connect(client1).deposit(
        "GBP",
        amountToDepositGBP
      );
      await depositGBP.wait();
      const depositEUR = await SimpleBank.connect(client1).deposit(
        "EUR",
        amountToDepositEUR
      );
      await depositEUR.wait();
      await SimpleBank.connect(client1).withdraw("EUR", amountToWithdrawEUR);
      const balanceGBP = await SimpleBank.connect(client1).getBalance("GBP");
      const balanceEUR = await SimpleBank.connect(client1).getBalance("EUR");
      const balanceUSD = await SimpleBank.connect(client1).getBalance("USD");
      // assert
      expect(balanceGBP).to.eq(amountToDepositGBP);
      expect(balanceEUR).to.eq(amountToDepositEUR - amountToWithdrawEUR);
      expect(balanceUSD).to.eq(amountToDepositUSD);
    });
  });

  describe("When the user wants to withdraw more than possible", () => {
    it("should throw when trying to withdraw", async () => {
      // arrange
      const amountToDepositGBP = 100;
      const amountToWithdrawGBP = 110;
      // act
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const depositGBP = await SimpleBank.connect(client1).deposit(
        "GBP",
        amountToDepositGBP
      );
      await depositGBP.wait();
      const withdrawGBP = async () =>
        SimpleBank.connect(client1).withdraw("GBP", amountToWithdrawGBP);
      // assert
      await expect(withdrawGBP()).to.revertedWith("Not enough fund");
    });
  });

  describe("when the user wants to use a new currency", () => {
    it("should add a new currency & register & deposit & withdraw & check balance", async () => {
      // arrange
      const currencyCode = "YEN";
      const amountToDepositYEN = 10000;
      const amountToWithdrawYEN = 2000;
      // act
      const add = await SimpleBank.addNewCurrency(currencyCode);
      await add.wait();
      const register = await SimpleBank.connect(client1).register();
      await register.wait();
      const deposit = await SimpleBank.connect(client1).deposit(
        "YEN",
        amountToDepositYEN
      );
      await deposit.wait();
      const withdraw = await SimpleBank.connect(client1).withdraw(
        "YEN",
        amountToWithdrawYEN
      );
      await withdraw.wait();
      const balance = await SimpleBank.connect(client1).getBalance("YEN");
      // assert
      expect(balance).to.eq(amountToDepositYEN - amountToWithdrawYEN);
    });
  });
});
