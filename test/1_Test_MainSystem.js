const { expect } = require("chai");
const { ethers } = require("hardhat");

let tscs, zimu, vt, st, access, audit, detection, divide1, onetime0, onetime2;
let tscsAsDeployer;
let owner, user1, user2;

describe("MainSystem_Test", function () {
  beforEach(async function () {
    // 获得区块链网络提供的测试账号
    const [deployer, addr1, addr2] = await ethers.getSigners();
    deployerAddress = deployer.address;
    owner = deployer;
    user1 = addr1;
    user2 = addr2;
    // 部署合约的工厂方法
    const TSCS = await ethers.getContractFactory("MainSystem");
    const ZIMU = await ethers.getContractFactory("ZimuToken");
    const VT = await ethers.getContractFactory("VideoToken");
    const ST = await ethers.getContractFactory("SubtitleToken");
    const ACCESS = await ethers.getContractFactory("AccessStrategy");
    const AUDIT = await ethers.getContractFactory("AuditStrategy");
    const DETECTION = await ethers.getContractFactory("DetectionStrategy");
    const DIVIDE1 = await ethers.getContractFactory("SettlementDivide1");
    const ONETIME0 = await ethers.getContractFactory("SettlementOneTime0");
    const ONETIME2 = await ethers.getContractFactory("SettlementOneTime2");
    // 部署合约
    tscs = await TSCS.deploy(deployerAddress);
    const tscsAddress = tscs.address;
    tscsAsDeployer = tscs.connect(deployer);
    zimu = await ZIMU.deploy(
      tscsAddress,
      deployerAddress,
      "0x21e19e0c9bab2400000",
      deployerAddress
    );
    const zimuAddress = zimu.address;
    vt = await VT.deploy(tscsAddress);
    const vtAddress = vt.address;
    st = await ST.deploy(tscsAddress);
    const stAddress = st.address;
    access = await ACCESS.deploy(deployerAddress);
    const accessAddress = access.address;
    audit = await AUDIT.deploy();
    const auditAddress = audit.address;
    detection = await DETECTION.deploy(deployerAddress, 5);
    const detectionAddress = detection.address;
    divide1 = await DIVIDE1.deploy(tscsAddress);
    const divide1Address = divide1.address;
    onetime0 = await ONETIME0.deploy(tscsAddress);
    const onetime0Address = onetime0.address;
    onetime2 = await ONETIME2.deploy(tscsAddress);
    const onetime2Address = onetime2.address;
    const tx1 = await tscsAsDeployer.setAuditStrategy(auditAddress);
    const tx2 = await tscsAsDeployer.setAccessStrategy(accessAddress);
    const tx3 = await tscsAsDeployer.setDetectionStrategy(detectionAddress);
    const tx4 = await tscsAsDeployer.setSettlementStrategy(
      0,
      onetime0Address,
      "OT0"
    );
    const tx5 = await tscsAsDeployer.setSettlementStrategy(
      1,
      divide1Address,
      "DI1"
    );
    const tx6 = await tscsAsDeployer.setSettlementStrategy(
      2,
      onetime2Address,
      "OTM2"
    );
    const tx7 = await tscsAsDeployer.setZimuToken(zimuAddress);
    const tx8 = await tscsAsDeployer.setVideoToken(vtAddress);
    const tx9 = await tscsAsDeployer.setSubtitleToken(stAddress);
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
  });
  it("Test Zimu transfer", async function () {
    let balanceUser1old = await zimu.balanceOf(user1.address);
    console.log("Zimu balance before transfer is", balanceUser1old);
    await zimu
      .connect(deployer)
      .transfer(addr1.address, ethers.utils.parseUnits("10", "ether"));
  });
  it("Test user join", async function () {
    await tscsAsDeployer.userJoin;
  });
});
