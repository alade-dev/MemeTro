const fs = require("fs");
const hre = require("hardhat");

async function main() {

  const TokenFactory = await hre.ethers.getContractFactory("TokenFactory");

  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying the contract with the account:", deployer.address);

  const tokenFactory = await TokenFactory.deploy(deployer.address);
  await tokenFactory.waitForDeployment();

  console.log("TokenFactory deployed to:", tokenFactory.target);

  fs.writeFileSync("contract.txt", tokenFactory.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
