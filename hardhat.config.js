require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
        compilers: [
            { version: "0.8.27" },
        ],
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [`0x` + `${process.env.PRIVATE_KEY}`],
    },
  },
};
