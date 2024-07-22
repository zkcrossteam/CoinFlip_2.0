const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

const ZKCVRF="0x50b663A057364C5DfA8b82F0a763A355078bdeB4";

async function main() {
  const CoinFlip = await ethers.getContractFactory("CoinFlip");
  const coinFlip = await CoinFlip.deploy(ZKCVRF, { value: ethers.utils.parseEther("0.2") });
  await coinFlip.deployed();
  const coinFlipAddress = await coinFlip.address;

  console.log("\n");
  console.log("CoinFlip deployed to: ", coinFlipAddress);
  console.log("\n");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
