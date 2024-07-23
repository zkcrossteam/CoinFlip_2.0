const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

const ZKCVRF="0x2eE398996503D61fc47a6621cF8aB1c9Bb243f1a";

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
