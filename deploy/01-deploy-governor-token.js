const { ethers } = require("hardhat");
const { networkConfig, developmentChains } = require("../helper-hardhat-config");
const verify = require("../helper-functions");

async function deployGovernanceToken(hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const networkName = network.name;
  const networkConfigEntry = networkConfig[networkName];

  if (!networkConfigEntry) {
    console.error(`Network configuration for '${networkName}' is not defined.`);
    process.exit(1);
  }

  log("----------------------------------------------------");
  log("Deploying GovernanceToken and waiting for confirmations...");

  const governanceToken = await deploy("GovernanceToken", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });

  log(`GovernanceToken deployed at ${governanceToken.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(governanceToken.address, []);
  }

  log(`Delegating to ${deployer}`);
  await delegate(governanceToken.address, deployer);
  log("Delegation complete!");
}

async function delegate(governanceTokenAddress, delegatedAccount) {
  const governanceToken = await ethers.getContractAt("GovernanceToken", governanceTokenAddress);
  const transactionResponse = await governanceToken.delegate(delegatedAccount);
  // await transactionResponse.wait(1);
  // console.log(`Checkpoints: ${await governanceToken.numCheckpoints(delegatedAccount)}`);
}

module.exports = deployGovernanceToken;
deployGovernanceToken.tags = ["all", "governor"];
