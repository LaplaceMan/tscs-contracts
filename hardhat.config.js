require('dotenv').config()
require("@nomiclabs/hardhat-waffle");
// require("hardhat-contract-sizer");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  defaultNetwork: "localhost",
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 20,
      },
    },
  },
  networks: {
    localhost: {
      url: process.env.LOCALHOST_URL,
    },
    goerli: {
      chainId: 5,
      url: process.env.GOERLI_URL,
      accounts: [
        process.env.ACCOUNT,
      ],
      gasPrice: 1000000000
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.EHTERSCAN_GOERLI_API
    },
    customChains: [
      {
        network: "goerli",
        chainId: 5,
        urls: {
          apiURL: "http://api-goerli.etherscan.io/api",
          browserURL: "https://goerli.etherscan.io"
        }
      }
    ]
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
};
