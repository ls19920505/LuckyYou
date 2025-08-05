const { ethers } = require("hardhat");

async function main() {
  const Lottery3D = await ethers.getContractFactory("Lottery3D");
  const lottery = await Lottery3D.deploy();
  if (lottery.waitForDeployment) {
    await lottery.waitForDeployment();
    console.log("Lottery3D deployed to:", await lottery.getAddress());
  } else {
    await lottery.deployed();
    console.log("Lottery3D deployed to:", lottery.address);
  }
}

module.exports = { main };

