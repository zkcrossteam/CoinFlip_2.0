
const { parseEther } = require("@ethersproject/units");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

const ZKCVRF="0x50b663A057364C5DfA8b82F0a763A355078bdeB4";

async function main() {
  const CoinFlip = await ethers.getContractAt("CoinFlip", "0xA2384Ab278C81AC2C5c4AD44C0c4B574A6fB37A0");

  const arg1 = BigInt(Math.floor(Math.random() * 1000) + 1);
  const arg2 = BigInt("38608566209366443851658898712947698042272167288516776474471539454638392565090");

  const tx  = await CoinFlip.bet(arg1,arg2,1, {value: parseEther("0.01").toString() });
  console.log(tx);
  await tx.wait();

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
