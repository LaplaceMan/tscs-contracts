const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
let tscs, zimu, vt, st, access, platform, audit, detection, divide1, onetime0, onetime2, versionManagement;
let tscsAsDeployer;
let owner, user1, user2, user3, user4, user5, user6;
const baseEthAmount = ethers.utils.parseUnits("60", "ether");
const unitEthAmount = ethers.utils.parseUnits("20", "ether");

describe("Subtitle_Realted_Test", function () {
  it("Prepare", async function () {
    // 获得区块链网络提供的测试账号
    const [deployer, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
    deployerAddress = deployer.address;
    owner = deployer;
    user1 = addr1;
    user2 = addr2;
    user3 = addr3;
    user4 = addr4;
    user5 = addr5;
    user6 = addr6;
    ("SubtitleVersionManagement");

    // 部署合约的工厂方法
    const TSCS = await ethers.getContractFactory("Murmes");
    const ZIMU = await ethers.getContractFactory("ZimuToken");
    const VT = await ethers.getContractFactory("VideoToken");
    const ST = await ethers.getContractFactory("SubtitleToken");
    const VAULTANDDEPOSIT = await ethers.getContractFactory("DepositMining");
    const PLATFORM = await ethers.getContractFactory("Platforms");
    const ACCESS = await ethers.getContractFactory("AccessStrategy");
    const AUDIT = await ethers.getContractFactory("AuditStrategy");
    const AUTHORITY = await ethers.getContractFactory("AuthorityStrategy");
    const DETECTION = await ethers.getContractFactory("DetectionStrategy");
    const DIVIDE1 = await ethers.getContractFactory("SettlementDivide1");
    const ONETIME0 = await ethers.getContractFactory("SettlementOneTime0");
    const ONETIME2 = await ethers.getContractFactory("SettlementOneTime2");
    const VERSIONMANAGEMENT = await ethers.getContractFactory("SubtitleVersionManagement");
    // 部署合约
    tscs = await TSCS.deploy(deployerAddress, deployerAddress);
    const tscsAddress = tscs.address;
    tscsAsDeployer = tscs.connect(deployer);
    zimu = await ZIMU.deploy(
      tscsAddress,
      "0x21e19e0c9bab2400000",
      deployerAddress
    );
    const zimuAddress = zimu.address;
    vt = await VT.deploy(tscsAddress);
    const vtAddress = vt.address;
    st = await ST.deploy(tscsAddress);
    const stAddress = st.address;
    const vault = await VAULTANDDEPOSIT.deploy(tscsAddress, deployerAddress);
    const vaultAddress = vault.address;
    platform = await PLATFORM.deploy(tscsAddress, zimuAddress);
    const platformAddress = platform.address;
    platformAsDeployer = platform.connect(deployer);
    access = await ACCESS.deploy(tscsAddress);
    const accessAddress = access.address;
    audit = await AUDIT.deploy(tscsAddress, 1);
    const auditAddress = audit.address;
    const authority = await AUTHORITY.deploy(tscsAddress, "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82");
    const authorityAddress = await authority.address;
    detection = await DETECTION.deploy(tscsAddress, 5);
    const detectionAddress = detection.address;
    divide1 = await DIVIDE1.deploy(tscsAddress);
    const divide1Address = divide1.address;
    onetime0 = await ONETIME0.deploy(tscsAddress);
    const onetime0Address = onetime0.address;
    onetime2 = await ONETIME2.deploy(tscsAddress);
    const onetime2Address = onetime2.address;
    versionManagement = await VERSIONMANAGEMENT.deploy(tscsAddress);
    const versionManagementAddress = versionManagement.address;
    await tscs.deployed();
    let tx;
    tx = await tscsAsDeployer.setNormalStrategy(0, auditAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setNormalStrategy(1, accessAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setNormalStrategy(2, detectionAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setNormalStrategy(3, authorityAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(0, onetime0Address, "OT0");
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(1, divide1Address, "D1");
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(2, onetime2Address, "OTM2");
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(0, zimuAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(1, vtAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(2, stAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(3, vaultAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(4, platformAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setComponentsAddress(6, versionManagementAddress);
    await tx.wait();
    // User1 获得Zimu代币
    await zimu.deployed();
    tx = await zimu.connect(owner).transfer(user1.address, baseEthAmount);
    await tx.wait();
    //注册语言
    tx = await tscsAsDeployer.registerLanguage(['cn', 'us', 'jp']);
    await tx.wait();
    // 提交申请
    tx = await zimu.connect(user1).approve(tscs.address, baseEthAmount);
    await tx.wait();
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    tx = await tscs
      .connect(user1)
      .submitApplication(tscsAddress, 0, 0, unitEthAmount, 1, date, "test");
    await tx.wait();
  });

  it("Upload subtitles", async () => {
    // 上传字幕
    let = tx = await tscs.connect(user2).uploadSubtitle(1, "test", 1, "0x1a2b");
    await tx.wait();
    tx = await tscs.connect(user3).uploadSubtitle(1, "testtest", 1, "0x1111");
    await tx.wait();
  })

  it("Update subtitles", async () => {
    // 更新字幕版本
    await expect(versionManagement.connect(user2).updateSubtitleVersion(1, "0x1a2a", "test2"))
      .to.emit(versionManagement, "UpdateSubtitleVersion")
      .withArgs(BigNumber.from("1"), BigNumber.from("0x1a2a"), "test2", 1);

    await expect(versionManagement.connect(user3).updateSubtitleVersion(2, "0x1110", "testtest2"))
      .to.emit(versionManagement, "UpdateSubtitleVersion")
      .withArgs(BigNumber.from("2"), BigNumber.from("0x1110"), "testtest2", 1);
  })

  it("Despoit for audit", async function () {
    let tx = await zimu.connect(owner).transfer(user4.address, baseEthAmount);
    await tx.wait();
    tx = await zimu.connect(owner).transfer(user5.address, baseEthAmount);
    await tx.wait();
    tx = await zimu.connect(owner).transfer(user6.address, baseEthAmount);
    await tx.wait();
    tx = await zimu
      .connect(user4)
      .approve(tscs.address, baseEthAmount);
    await tx.wait();
    tx = await zimu
      .connect(user5)
      .approve(tscs.address, baseEthAmount);
    await tx.wait();
    tx = await zimu
      .connect(user6)
      .approve(tscs.address, baseEthAmount);
    await tx.wait();
    tx = await tscs.connect(user4).userJoin(user4.address, baseEthAmount);
    await tx.wait();
    tx = await tscs.connect(user5).userJoin(user5.address, baseEthAmount);
    await tx.wait();
    tx = await tscs.connect(user6).userJoin(user6.address, baseEthAmount);
    await tx.wait();
    let subtitleEvilOwnerInfo = await tscsAsDeployer.getUserBaseInfo(user2.address);
    console.log("BEFORE Evil Maker", subtitleEvilOwnerInfo);
    let subtitleNoramlOwnerInfo = await tscsAsDeployer.getUserBaseInfo(user3.address);
    console.log("BEFORE Normal Maker", subtitleNoramlOwnerInfo);
    let subtitleSuppoterInfo = await tscsAsDeployer.getUserBaseInfo(user6.address);
    console.log("BEFORE Evil", subtitleSuppoterInfo);
    let subtitleRepoterInfo = await tscsAsDeployer.getUserBaseInfo(user4.address);
    console.log("BEFORE Normal", subtitleRepoterInfo);
  });

  it("Test report (delete) subtitle", async function () {
    // 给恶意字幕好评
    await expect(tscs.connect(user6).evaluateSubtitle(1, 0))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("1"), user6.address, 0);
    // 举报恶意字幕
    await expect(tscs.connect(user4).evaluateSubtitle(1, 1))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("1"), user4.address, 1);
    await expect(tscs.connect(user5).evaluateSubtitle(1, 1))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("1"), user5.address, 1);
    // 最新字幕状态
    let subtitleAuditState = await tscsAsDeployer.getSubtitleAuditInfo(1);
    console.log("Subtitle audit state:", subtitleAuditState);
    let subtitleState = await tscsAsDeployer.getSubtitleBaseInfo(1);
    console.log("Subtitle state:", subtitleState);

    subtitleOwnerInfo = await tscsAsDeployer.getUserBaseInfo(user2.address);
    console.log("AFTER:Deleted subtitle's evil maker Info", subtitleOwnerInfo);
    subtitleSuppoterInfo = await tscsAsDeployer.getUserBaseInfo(user6.address);
    console.log("AFTER:Deleted subtitle's evil Info", subtitleSuppoterInfo);
    subtitleRepoterInfo = await tscsAsDeployer.getUserBaseInfo(user4.address);
    console.log("AFTER:Deleted subtitle's normal Info", subtitleRepoterInfo);
  })

  it("Test delete invaild subtitle versions", async function () {
    let vaildVersion = await versionManagement.connect(owner).getLatestValidVersion(1);
    console.log("Evil subtitle vaild version:", vaildVersion);
    let tx = await versionManagement.connect(user1).deleteInvaildSubtitle(1);
    tx.wait();
    vaildVersion = await versionManagement.connect(user1).getLatestValidVersion(1);
    console.log("Latest evil subtitle vaild version:", vaildVersion);
  });

  it("Test adopt subtitle", async function () {
    // 给正常字幕差评
    await expect(tscs.connect(user6).evaluateSubtitle(2, 1))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("2"), user6.address, 1);
    // 给优质字幕好评
    await expect(tscs.connect(user4).evaluateSubtitle(2, 0))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("2"), user4.address, 0);
    await expect(tscs.connect(user5).evaluateSubtitle(2, 0))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("2"), user5.address, 0);
    // 最新字幕状态
    let subtitleAuditState = await tscsAsDeployer.getSubtitleAuditInfo(2);
    console.log("Subtitle audit state:", subtitleAuditState);
    let subtitleState = await tscsAsDeployer.getSubtitleBaseInfo(2);
    console.log("Subtitle state:", subtitleState);
    let applicationState = await tscsAsDeployer.tasks(1);
    console.log("Application state:", applicationState);

    subtitleOwnerInfo = await tscsAsDeployer.getUserBaseInfo(user3.address);
    console.log("AFTER:Adopted subtitle's normal maker Info", subtitleOwnerInfo);
    subtitleSuppoterInfo = await tscsAsDeployer.getUserBaseInfo(user4.address);
    console.log("AFTER:Adopted subtitle's normal Info", subtitleSuppoterInfo);
    subtitleRepoterInfo = await tscsAsDeployer.getUserBaseInfo(user6.address);
    console.log("AFTER:Adopted subtitle's evil Info", subtitleRepoterInfo);
  });
});
