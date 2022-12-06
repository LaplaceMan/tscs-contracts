require("@nomiclabs/hardhat-waffle");
require("hardhat-contract-sizer");
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
      url: "http://localhost:8545",
    },
    goerli: {
      chainId: 5,
      url: "https://goerli.infura.io/v3/",
      accounts: [
        "",
      ]
    },
  },
  etherscan: {
    apiKey: {
      goerli: ""
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
