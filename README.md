# TSCS - A Blockchain-Based Tokenized Subtitle Crowdsourcing System

## Install Dependencies

`git clone https://github.com/LaplaceMan/tscs-contracts`

`npm install`

## Compile Contracts

`npx hardhat compile --force`

## Deploy Contracts

`npx hardhat run scripts/deploy.js --network <network-name>`

> 先部署 TSCS 主合约 SubtitleSystem.sol ，构造函数输入参数为 DAO 合约地址
> 然后部署代币合约 VT.sol 、Zimu.sol、ST.sol ，构造函数输入参数为主合约地址（和 DAO 合约地址）
> 最后部署策略合约 AccessStrategy.sol（访问权限策略）、AuditStrategy.sol（审核策略）、DetectionStrategy.sol（相似度检测策略）和三个结算策略合约。其中，结算策略合约构造函数输入参数为主合约地址，其余为 DAO 合约地址

## Error Explain

| Label | Explain                |
| ----- | ---------------------- |
| ER0   | Already Exists         |
| ER1   | Invaild Data           |
| ER2   | Not Existence          |
| ER3   | State Changed          |
| ER4   | Have Evaluated         |
| ER5   | No Permission          |
| ER6   | Not Support            |
| ER7   | GAM Only One-time      |
| ER9   | Language Inconsistency |
| ER10  | High Similarity        |
| ER11  | Invalid Settlement     |

## Contracts UML Diagram

![Contracts UML](./contractsUMLDiagram.svg)

## Next Update

- [ ] 使用 Zimu 代币兑换 NFT，NFT 的差异化设计
- [ ] Zimu 代币的经济模型（使用途径）
- [ ] DAO 管理
- [ ] 仲裁（法庭）机制
- [ ] 字幕组 DAO
- [ ] 粉丝空投奖励
- [ ] SBT 收益解放或放大，由社区认证专业审核员或字幕制作者

## Test Function Task

### Function In **SubtitleSystem.sol**

- [ ] submitApplication
- [ ] createVideo
- [ ] uploadSubtitle
- [ ] updateUsageCounts
- [ ] evaluateSubtitle
- [ ] preExtractMode0
- [ ] preExtract
- [ ] withdraw
- [ ] cancel
- [ ] recover

### Function In **EntityManager.sol**

- [ ] registerLanguage
- [ ] userJoin

### Function In **PlatformManager.sol**

- [ ] platfromJoin
- [ ] platformRate

### Function In **VideoManager.sol**

- [ ] updateViewCounts

# Token Economics

1. **VT(Video Token)**
   - ERC1155 标准
   - 由平台为各自发行的稳定币价值作背书
   - 当支付策略与在视频平台的收益相绑定时，利益相关者获得的是由相应平台发行的稳定币
   - 由 TSCS 发行的稳定币由 Zimu 和 用户兑换的稳定币作背书
2. **Zimu(Zimu Token)**
   - ERC20 标准
   - TSCS 发行的通胀型平台代币
   - 当用户参与社区建设（字幕被确认时，字幕制作者和相应的审核员）时获得代币奖励
   - 用户使用（销毁） Zimu 代币时可以兑换 NFT
   - 基于信誉度和代币质押双重验证机制，用户注册或因信誉度过低补充质押代币时，需要使用该代币
   - 因用户恶意行为扣除的 Zimu 代币将保留在金库中，一部分用于仲裁时奖励仲裁成功的发起人和受害者，存在存储最大值，多余的将被销毁
   - 作为空投奖励
3. **ST(Subtitle Token)**
   - ERC721 标准
   - 用户上传字幕时自动生成
   - 用户可根据已上传的 ST（出于安全性，会有其它限制：申请已被确认且经过审核期）和 Zimu 代币生成 NFT
4. **SBT**
   - ERC721 未来计划
   - 为优秀的字幕制作者或深度用户（审核员、视频创作者）发放灵魂绑定代币
   - 基于 SBT 设计奖励策略
