
const { parseEther } = require("@ethersproject/units");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

async function main() {
  const CoinFlip = await ethers.getContractAt("CoinFlip", "0x40D18b8374c41c58A8d0Fa3a075EB2F80C202D2f");

  const arg1 = BigInt(Math.floor(Math.random() * 1000) + 1);
  const arg2 = BigInt("6632802288658732681706432291368097154356469295689759800133277258786980102956");

  const tx  = await CoinFlip.bet(arg1,arg2,1, {value: parseEther("0.01").toString() });
  console.log(tx);
  await tx.wait();

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
