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


## Deployed Contracts

### Polygon Mumbai - 0x80001

| Name                               | Contract Address                           |
| ---------------------------------- | ------------------------------------------ |
| Murmes                             | 0x2E2F1434Ce4D4Ec45bE6C3Cf4c6C70767D46259f |
| Platform Token                     | 0x6FAEB796a7C0ecadE262c80F1503A777135860f6 |
| Item Token                         | 0x86C57f0be2b5a7bA45F5E913Cf973060405CA4bD |
| Vault                              | 0xb286d7f6BbDfFD33E1c2Bc2667E849f1d702CF9F |
| Murmes Authority                   | 0xbA7a77E32F985D2264A87A791037c636ff28fe3B |
| Platforms                          | 0xea241696708f147bAad0baC2f0aFD5A265DEb0E3 |
| Component Global                   | 0x2993BDc5F16772f96A7Ee390C1E5A34f84B6a6Cf |
| Module Global                      | 0x10A383577337F45337650A8A2394a92A16cB9271 |
| Settlement                         | 0xfbB0B5FDb83f8DD0B7c705cb06a7dd0ce8F87162 |
| Version Management                 | 0x1B0698B118aD0adF0df020be4f2f71e07b955667 |
| Arbitration                        | 0xD6308923de30479C308FF1857C05244B250B5013 |
| Authority                          | 0x2E4c4CDefA5239599DFF07AC17D2eeA4868CE2AA |
| Access                             | 0x216dB93D0752A07FB44568eEC4Fa8B43B43378c7 |
| Audit                              | 0x7880aAAd3578Dc9769aB44ddE276914FD0EE9205 |
| Detection                          | 0x94037109396EEAf52FC67441C5342b8Da5498109 |
| Settlement OT0                     | 0xfe8fF542B2a578a7D72a629BcC8975b4bDa92cdF |
| Settlement D1                      | 0xd3b876B2dC3fE70daf6446C96e5de32366F14F2b |
| Settlement OT2                     | 0x1B6947aa388b29f61B09050B0276eECB23F73DF6 |
| Default Authority                  | 0x2315195Ac25A18926E36E6336e7763C8a4A79134 |
| ERC20 Mintable                     | 0x4996D5fd0A9C247c85eBC56f1A2A64c1A6980eAd |
| Lens Protocol                      | 0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5 |
| Lens Authority                     | 0xE41136A82771aA37b474eCE1a29Ba9826823131A |
| Lens Module                        | 0xa9917c3Aa1aCca02f5DfF305107883F564a47db6 |

<!-- Murmes Contract: 0x2E2F1434Ce4D4Ec45bE6C3Cf4c6C70767D46259f
Platform Token Contract: 0x6FAEB796a7C0ecadE262c80F1503A777135860f6
Item Token Contract: 0x86C57f0be2b5a7bA45F5E913Cf973060405CA4bD
Vault Contract: 0xb286d7f6BbDfFD33E1c2Bc2667E849f1d702CF9F
Murmes Authority Contract: 0xbA7a77E32F985D2264A87A791037c636ff28fe3B
Platforms Contract: 0xea241696708f147bAad0baC2f0aFD5A265DEb0E3
Component Global Contract: 0x2993BDc5F16772f96A7Ee390C1E5A34f84B6a6Cf
Module Global Contract: 0x10A383577337F45337650A8A2394a92A16cB9271
Settlement Contract: 0xfbB0B5FDb83f8DD0B7c705cb06a7dd0ce8F87162
Version Management Contract: 0x1B0698B118aD0adF0df020be4f2f71e07b955667
Arbitration Contract: 0xD6308923de30479C308FF1857C05244B250B5013
Authority Contract: 0x2E4c4CDefA5239599DFF07AC17D2eeA4868CE2AA
Access Contract: 0x216dB93D0752A07FB44568eEC4Fa8B43B43378c7
Audit Contract: 0x7880aAAd3578Dc9769aB44ddE276914FD0EE9205
Detection Contract: 0x94037109396EEAf52FC67441C5342b8Da5498109
Settlement OT0 Contract: 0xfe8fF542B2a578a7D72a629BcC8975b4bDa92cdF
Settlement D1 Contract: 0xd3b876B2dC3fE70daf6446C96e5de32366F14F2b
Settlement OT2 Contract: 0x1B6947aa388b29f61B09050B0276eECB23F73DF6
Default Authority Contract: 0x2315195Ac25A18926E36E6336e7763C8a4A79134 -->