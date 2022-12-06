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
      url: "http://10.201.1.235:8545",
    },
    goerli: {
      chainId: 5,
      url: "https://goerli.infura.io/v3/",
      accounts: [
        "0xc5005590242b8a10728c213ef2e7572470d4a9ff18883ada078b8b03fe8997df",
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
