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
    quorum: {
      url: "http://10.201.1.237:8545",
      accounts: [
        "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"
      ]
    },
    goerli: {
      chainId: 5,
      url: "https://eth-mainnet.alchemyapi.io/v2/123abc123abc123abc123abc123abcde", // your network rpc
      accounts: [
        "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63",
      ],
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
};
