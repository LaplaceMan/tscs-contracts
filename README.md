# TSCS

## Install Dependencies

1. git clone https://github.com/LaplaceMan/tscs-contracts
2. npm install

## Compile Contracts

1. npx hardhat compile --force

## Deploy Contracts

1. npx hardhat run scripts/deploy.js --network \<network-name \>

## Next Update

1. 默认结算策略下支付资产的拓展化（目前设计为使用由 TSCS 发行的稳定币）
2. 添加制作字幕手续费
3. 使用 Zimu 代币兑换 NFT，NFT 的差异化设计
4. Zimu 代币的经济模型（使用途径）
5. DAO 金库管理（金库合约分离）
6. 仲裁（法庭）机制
7. 字幕组 DAO
8. 结算策略模块化合约优化
9. 粉丝空投奖励
