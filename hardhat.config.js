/** @type import('hardhat/config').HardhatUserConfig */
require('hardhat-contract-sizer');
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 20
      }
    }
  },
  networks: {
    hardhat: {
    }, // npx hardhat node
    localhost: {
      url: "http://127.0.0.1:8545" 
    }, // ganache ...
    goerli: {
      chainId: 5,
      url: "https://eth-mainnet.alchemyapi.io/v2/123abc123abc123abc123abc123abcde", // your network rpc 
      accounts: ['44bd43a04bab193e258d1e29d267a74fe3b4ced6060db617fd210b26be6d9618'] //your private key
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  }
};
