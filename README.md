<div align="center"> 
<img src="./logo.png" height="170px"/>
<p><h1>MURMES</h1></p>
<p>
<a href="https://www.youtube.com/channel/UCcIqRf9rq1oAN7pprsfpM8w"> <img src="https://img.shields.io/badge/YouTube-FF0000?style=flat&logo=youtube&logoColor=white" height="25px" /> </a>
<a href="https://twitter.com/laplaceman1007"> <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=flat&logo=twitter&logoColor=white" height="25px" /> </a>
<img src="https://img.shields.io/badge/version-v0.4.0-blue" height="25px" />
 </a>
</a>
<img src="https://img.shields.io/badge/license-LGPL3.0 only-blue.svg?style=plastic" height="25px" />
 </a>
</p>
<p>
TSCS: A Blockchain-Based Tokenized Subtitle Crowdsourcing System (Old Name)
</P>
</div>

[Murmes](https://murmes.gitbook.io/murmes-protocol/) is a blockchain-based tokenized subtitling crowdsourcing system. It is dedicated to solving the problem of "language silos" in the current video media platform. Through a complete set of trading mechanisms and economic models, video creators, subtitle makers, viewers, and investors are connected in an open, transparent, and multi-profit ecosystem.

## Install Dependencies

`git clone https://github.com/LaplaceMan/tscs-contracts`

`npm install`

## Compile Contracts

`npx hardhat compile --force`

## Deploy Contracts

`npx hardhat run scripts/deploy.js --network <network-name>`

## Test Contracts

`npx hardhat test .\scripts\<Test script>.js --network <Network name>`

## Verify Contracts

`npx hardhat clean`

`npx hardhat verify --constructor-args .\scripts\verifyContractArguments\<constructor arguments>.js --network goerli <On-chain contract address>`

> 将代码上传到 ehterscan 或其它区块链浏览器，即使在翻墙的情况下也可能出现超时或无法连接的情况，可参考 [文章](https://learnblockchain.cn/question/2939)。

## Error Explain

| Label | Explain               |
| ----- | --------------------- |
| ER0   | Already Exists        |
| ER1   | Invaild Data          |
| ER2   | Not Existence         |
| ER3   | State Changed         |
| ER4   | Have Evaluated        |
| ER5   | No Permission         |
| ER6   | Not Support           |
| ER7   | GAM Only One-time     |
| ER9   | Require Inconsistency |
| ER10  | High Similarity       |
| ER11  | Invalid Settlement    |
| ER12  | Transaction failed    |

## Contracts UML Diagram

![Contracts UML](./contractsUMLDiagram.svg)

## Next Update

- [ ] 字幕组 DAO
- [ ] SBT 设计，由项目方空投
- [ ] 使用 Zimu 代币和 VT 代币兑换 NFT

## Deployed Contracts

### Ethereum Goerli - 0x5

#### v0.2.0

| Name                               | Contract Address                           |
| ---------------------------------- | ------------------------------------------ |
| Murmes                             | 0xD18bD5B3439c7994988534F2Bdbb64A0556085BB |
| Zimu Token                         | 0x195D1F8BC906f1129a1Ab177E7536CAe9b7E142b |
| Video Token                        | 0xF0D5f127AC8e8582a2C3fE228203c1015c397d3E |
| Subtitle Token                     | 0x223dbc19cA1636cCd044F8eef5c0d829fA632C4c |
| Vault Manager                      | 0xE9aF9E85E0D3aD5c38Fb3cd71fecAb694030787e |
| Platform Manager                   | 0xcf757954A689834dE86182476E38e22A3fE645d4 |
| Access Strategy                    | 0x8bA47eBcc3877ddE208de5abE5a5Cb973CF44437 |
| Audit Strategy                     | 0xb3963a71d52E6270Bc6C066fC36DB94B20F6fE92 |
| Detection Strategy                 | 0x90b2573320191040E05471FECE0305cDd6700cB2 |
| Settlement-Divide (DR1)            | 0x2c7EFFBc537E3a9404d0637297C6E3C22Ee00217 |
| Settlement-Onetime (OT0)           | 0x61F10AbA9e6087c1EA315d1651BF09977ee466d7 |
| Settlement-Onetime Mortgage (OTM2) | 0xbBdD22dFE991F5366AC6895B18c6A2Fe11c892f1 |

### Polygon Mumbai - 0x80001

#### v0.5.0

| Name                               | Contract Address                           |
| ---------------------------------- | ------------------------------------------ |
| Murmes                             | 0x87042950BFCE9b365E3C1E21C5DD343Cb8AcDA95 |
| Zimu Token                         | 0x8928C5568a7Bc0da7F0f2CF6027AC7F3f8bf68f3 |
| Video Token                        | 0xb70B66d5185E47C234e6779be4C552f80AA19425 |
| Subtitle Token                     | 0xF5A0BAcB03958E1b5EBdA72C6963C9FC19e021dF |
| Vault Manager                      | 0x664F3747fB045672FA2a84f50540CBe4bDf52832 |
| Platform Manager                   | 0xa671E667552218A495B2F5a53ec0B681f1c965c5 |
| Access Strategy                    | 0x4915Fb358464A9b7Ab1E41834de6476baa7Fc1C3 |
| Audit Strategy                     | 0x990214635329D55e4Cc3C7d6e32a400b22A5a31e |
| Authority Strategy                 | 0x7851CB87dbDF86Dd76ee1e8BD1D6Cfe95446d2Ed |
| Detection Strategy                 | 0x75629924914ba13A15c949b44e2e565D8103fC70 |
| Settlement-Divide (D1)             | 0x6040AeF09e463aE01E6d9439a0fFfa11aD6B874f |
| Settlement-Onetime (OT0)           | 0x7cE090BfD917c5eE49FA04a42A14c35f4237D296 |
| Settlement-Onetime Mortgage (OTM2) | 0x844BFdb48615aE498EB6da9D94f5ee42eB462f1f |
| Subtitle Version Manager           | 0xD5E36C6ad1B64924334Ef2e8B68DbEad194BA195 |
| Arbitration                        | 0x7A3Aa3A819565bBcDE08a067cf7827589f83a708 |
| Lens Fee Collect Module For Murmes | 0x20d1933080d7B77EcF09EaA7F32b81E1a17c28a1 |





