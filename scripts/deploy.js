const { ethers } = require("hardhat");
const main = async () => {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = deployer.address;
  // 部署 Murmes 主合约
  const TSCS = await ethers.getContractFactory("Murmes");
  const tscs = await TSCS.deploy(deployerAddress, deployerAddress); //owner 地址（DAO地址）+ 多签地址
  const tscsAddress = tscs.address;
  console.log("tscsAddress", tscsAddress);
  const tscsExemple = await TSCS.attach(tscsAddress);
  // 部署平台代币 Zimu 合约（ERC20）
  const ZIMU = await ethers.getContractFactory("ZimuToken");
  const zimu = await ZIMU.deploy(
    tscsAddress, // Murmes合约地址
    "0x33b2e3c9fd0804000000000", // 铸造代币总量
    deployerAddress // 线性解锁代币合约地址
  );
  const zimuAddress = zimu.address;
  console.log("zimuAddress", zimuAddress);
  // 部署稳定币 VT 合约（ERC1155）
  const VT = await ethers.getContractFactory("VideoToken");
  const vt = await VT.deploy(tscsAddress);
  const vtAddress = vt.address;
  console.log("vtAddress", vtAddress);
  // 部署字幕代币 ST 合约（ERC721）
  const ST = await ethers.getContractFactory("SubtitleToken");
  const st = await ST.deploy(tscsAddress);
  const stAddress = st.address;
  console.log("stAddress", stAddress);
  //部署金库合约
  // const VAULT = await ethers.getContractFactory("Vault");
  // const vault = await VAULT.deploy(deployerAddress, tscsAddress);
  // const vaultAddress = vault.address;
  // console.log("vaultAddress", vaultAddress);
  const VAULTANDDEPOSIT = await ethers.getContractFactory("DepositMining");
  const vaultAndDeposit = await VAULTANDDEPOSIT.deploy(tscsAddress, deployerAddress);
  const vaultAndDepositAddress = vaultAndDeposit.address;
  console.log("vaultAndDepositAddress", vaultAndDepositAddress);
  //部署平台合约
  const PLATFORM = await ethers.getContractFactory("Platforms");
  const platform = await PLATFORM.deploy(tscsAddress, zimuAddress);
  const platformAddress = platform.address;
  console.log("platformAddress", platformAddress);
  // 部署策略合约
  // 访问策略
  const ACCESS = await ethers.getContractFactory("AccessStrategy");
  const access = await ACCESS.deploy(tscsAddress);
  const accessAddress = access.address;
  console.log("accessAddress", accessAddress);
  // 审核策略
  const AUDIT = await ethers.getContractFactory("AuditStrategy");
  const audit = await AUDIT.deploy(tscsAddress, 1);
  const auditAddress = audit.address;
  console.log("auditAddress", auditAddress);
  // 访问权限策略（Lens中间件）
  const AUTHORITY = await ethers.getContractFactory("AuthorityStrategy");
  const authority = await AUTHORITY.deploy(tscsAddress, "0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5");
  const authorityAddress = await authority.address;
  console.log("authorityAddress", authorityAddress);
  // 相似度检测策略
  const DETECTION = await ethers.getContractFactory("DetectionStrategy");
  const detection = await DETECTION.deploy(tscsAddress, 5); //owner 地址（DAO地址）, 阈值
  const detectionAddress = detection.address;
  console.log("detectionAddress", detectionAddress);
  // 部署结算策略合约
  // 分成结算
  const DIVIDE1 = await ethers.getContractFactory("SettlementDivide1");
  const divide1 = await DIVIDE1.deploy(tscsAddress);
  const divide1Address = divide1.address;
  console.log("divide1Address", divide1Address);
  // 一次性结算
  const ONETIME0 = await ethers.getContractFactory("SettlementOneTime0");
  const onetime0 = await ONETIME0.deploy(tscsAddress);
  const onetime0Address = onetime0.address;
  console.log("onetime0Address", onetime0Address);
  // 一次性抵押结算
  const ONETIME2 = await ethers.getContractFactory("SettlementOneTime2");
  const onetime2 = await ONETIME2.deploy(tscsAddress);
  const onetime2Address = onetime2.address;
  console.log("onetime2Address", onetime2Address);
  // 部署挂载合约
  // 部署字幕版本管理合约
  const VERSIONMANAGEMENT = await ethers.getContractFactory("SubtitleVersionManagement");
  const versionManagement = await VERSIONMANAGEMENT.deploy(tscsAddress);
  const versionManagementAddress = versionManagement.address;
  console.log("versionManagement", versionManagementAddress);
  //部署仲裁合约
  const ARBITRATION = await ethers.getContractFactory("Arbitration");
  const arbitration = await ARBITRATION.deploy(tscsAddress);
  const arbitrationAddress = arbitration.address;
  console.log("arbitrationAddress", arbitrationAddress);
  // 主合约设置策略合约地址
  const tx1 = await tscsExemple.setNormalStrategy(0, auditAddress);
  const tx2 = await tscsExemple.setNormalStrategy(1, accessAddress);
  const tx3 = await tscsExemple.setNormalStrategy(2, detectionAddress);
  const tx4 = await tscsExemple.setNormalStrategy(3, authorityAddress);
  const tx5 = await tscsExemple.setSettlementStrategy(
    0,
    onetime0Address,
    'OT0'
  );
  const tx6 = await tscsExemple.setSettlementStrategy(1, divide1Address, 'D1');
  const tx7 = await tscsExemple.setSettlementStrategy(
    2,
    onetime2Address,
    'OTM2'
  );
  // 主合约设置代币合约地址
  const tx8 = await tscsExemple.setComponentsAddress(0, zimuAddress);
  const tx9 = await tscsExemple.setComponentsAddress(1, vtAddress);
  const tx10 = await tscsExemple.setComponentsAddress(2, stAddress);
  const tx11 = await tscsExemple.setComponentsAddress(3, vaultAndDepositAddress);
  const tx12 = await tscsExemple.setComponentsAddress(4, platformAddress);
  const tx13 = await tscsExemple.setComponentsAddress(5, arbitrationAddress);
  const tx14 = await tscsExemple.setComponentsAddress(6, versionManagementAddress);
  const tx15 = await tscsExemple.registerLanguage(['zh-CN', 'en-US', 'zh-TW', 'zh-HK', 'en-GB', 'ja-JP', 'ko-KR', 'fr-CA', 'pt-PT', 'es-CL', 'it-IT'])
  console.log("\n");
  console.log("setAuditStrategy", tx1);
  console.log("setAccessStrategy", tx2);
  console.log("setDetectionStrategy", tx3);
  console.log("setAuthorityStrategy", tx4);
  console.log("setSettlementStrategy0", tx5);
  console.log("setSettlementStrategy1", tx6);
  console.log("setSettlementStrategy2", tx7);
  console.log("setZimuToken", tx8);
  console.log("setVideoToken", tx9);
  console.log("setSubtitleToken", tx10);
  console.log("setVault", tx11);
  console.log("platformAddress", tx12);
  console.log("setArbitration", tx13);
  console.log("setVersionManagement", tx14);
  console.log("registerLanguage", tx15);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
