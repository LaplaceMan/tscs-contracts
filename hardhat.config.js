/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("hardhat-contract-sizer");
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
      url: "http://10.201.1.236:8545",
      accounts: [
        "2be9c8ef318c921eb89cc4cdfed1e1c72003e476f0f90f5d288a320513008064",
      ]
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
};
