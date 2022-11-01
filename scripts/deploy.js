const { ethers } = require("hardhat");
const main = async () => {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = deployer.address;
  // 部署 TSCS 主合约
  const TSCS = await ethers.getContractFactory("SubtitleSystem");
  const tscs = await TSCS.deploy(deployerAddress); //owner 地址（DAO地址）
  const tscsAddress = tscs.address;
  console.log("tscsAddress", tscsAddress);
  const tscsExemple = await TSCS.attach(tscsAddress);
  // 部署平台代币 Zimu 合约（ERC20）
  const ZIMU = await ethers.getContractFactory("ZimuToken");
  const zimu = await ZIMU.deploy(
    tscsAddress,
    deployerAddress,
    "0x21e19e0c9bab2400000",
    deployerAddress
  );
  const zimuAddress = zimu.address;
  console.log("zimuAddress", zimuAddress);
  // 部署稳定币 VT 合约（ERC1155）
  const VT = await ethers.getContractFactory("VideoToken");
  const vt = await VT.deploy(tscsAddress);
  const vtAddress = vt.address;
  console.log("vtAddress", vtAddress);
  // 部署字幕嗲比 ST 合约（ERC721）
  const ST = await ethers.getContractFactory("SubtitleToken");
  const st = await ST.deploy(tscsAddress);
  const stAddress = st.address;
  console.log("stAddress", stAddress);
  // 部署策略合约
  // 访问策略
  const ACCESS = await ethers.getContractFactory("AccessStrategy");
  const access = await ACCESS.deploy(deployerAddress);
  const accessAddress = access.address;
  console.log("accessAddress", accessAddress);
  // 审核策略
  const AUDIT = await ethers.getContractFactory("AuditStrategy");
  const audit = await AUDIT.deploy();
  const auditAddress = audit.address;
  console.log("auditAddress", auditAddress);
  // 相似度检测策略
  const DETECTION = await ethers.getContractFactory("DetectionStrategy");
  const detection = await DETECTION.deploy(deployerAddress, 5); //owner 地址（DAO地址）, 阈值
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
  // 主合约设置策略合约地址
  const tx1 = await tscsExemple.setAuditStrategy(auditAddress);
  const tx2 = await tscsExemple.setAccessStrategy(accessAddress);
  const tx3 = await tscsExemple.setDetectionStrategy(detectionAddress);
  const tx4 = await tscsExemple.setSettlementStrategy(
    0,
    onetime0Address,
    "OT0"
  );
  const tx5 = await tscsExemple.setSettlementStrategy(1, divide1Address, "DI1");
  const tx6 = await tscsExemple.setSettlementStrategy(
    2,
    onetime2Address,
    "OTM2"
  );
  // 主合约设置代币合约地址
  const tx7 = await tscsExemple.setZimuToken(zimuAddress);
  const tx8 = await tscsExemple.setVideoToken(vtAddress);
  const tx9 = await tscsExemple.setSubtitleToken(stAddress);
  console.log("\n");
  console.log("setAuditStrategy", tx1);
  console.log("setAccessStrategy", tx2);
  console.log("setDetectionStrategy", tx3);
  console.log("setSettlementStrategy0", tx4);
  console.log("setSettlementStrategy1", tx5);
  console.log("setSettlementStrategy2", tx6);
  console.log("setZimuToken", tx7);
  console.log("setVideoToken", tx8);
  console.log("setSubtitleToken", tx9);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
