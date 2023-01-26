import { ethers } from "hardhat";

async function main() {
  const SimpleBankFactory = await ethers.getContractFactory("SimpleBank");
  const SimpleBank = await SimpleBankFactory.deploy();

  await SimpleBank.deployed();

  console.log(`deployed to ${SimpleBank.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
