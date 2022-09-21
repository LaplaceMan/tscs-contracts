import ethers from 'ethers'
async function main() {
    const [deployer] = await ethers.getSigners();	
    const deployerAddress = deployer.address;
    // 部署 TSCS 主合约
    const TSCS = await ethers.getContractFactory("SubtitleSystem");
    const tscs = await TSCS.deploy(deployerAddress); //owner 地址（DAO地址）
    const tscsAddress = tscs.address;
    const tscsExemple = await TSCS.attach(tscsAddress);
    // 部署平台代币 Zimu 合约（ERC20）
    const ZIMU = await ethers.getContractFactory("Zimu");
    const zimu = await ZIMU.deploy(tscsAddress);
    const zimuAddress = zimu.address;
    // 部署稳定币 VT 合约（ERC1155）
    const VT = await ethers.getContractFactory("VT");
    const vt = await VT.deploy(tscsAddress);
    const vtAddress = vt.address;
    // 部署策略合约
    // 访问策略
    const ACCESS = await ethers.getContractFactory("AccessStrategy");
    const access = await ACCESS.deploy(tscsAddress);
    const accessAddress = access.address;
    // 审核策略
    const AUDIT = await ethers.getContractFactory("AuditStrategy");
    const audit = await AUDIT.deploy();
    const auditAddress = audit.address;
    // 相似度检测策略
    const DETECTION = await ethers.getContractFactory("DetectionStrategy");
    const detection = await DETECTION.deploy(deployerAddress, 5); //owner 地址（DAO地址）, 阈值
    const detectionAddress = detection.address;
    // 部署结算策略合约
    // 分成结算
    const DIVIDE1 = await ethers.getContractFactory("SettlementDivide1");
    const divide1 = await DIVIDE1.deploy(tscsAddress);
    const divide1Address = divide1.address;
    // 一次性结算
    const ONETIME0 = await ethers.getContractFactory("SettlementOneTime0");
    const onetime0 = await ONETIME0.deplo(tscsAddress);
    const onetime0Address = onetime0.address;
    // 一次性抵押结算
    const ONETIME2 = await ethers.getContractFactory("SettlementOneTime2");
    const onetime2 = await ONETIME2.deplo(tscsAddress);
    const onetime2Address = onetime2.address;
    // 主合约设置策略合约地址
    const tx1 = await tscsExemple.setDefaultAuditStrategy(auditAddress);
    const tx2 = await tscsExemple.setDefaultAccessStrategy(accessAddress);
    const tx3 = await tscsExemple.setDefaultDetectionStrategy(detectionAddress);
    const tx4 = await tscsExemple.setSettlementStrategy(0, onetime0Address, 'One Time');
    const tx5 = await tscsExemple.setSettlementStrategy(1, divide1Address, 'Divide');
    const tx6 = await tscsExemple.setSettlementStrategy(2, onetime2Address, 'One-time Mortgage');
    // 主合约设置代币合约地址
    const tx7 = await tscsExemple.setZimuToken(zimuAddress);
    const tx8 = await tscsExemple.setZimuToken(vtAddress);
}
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });