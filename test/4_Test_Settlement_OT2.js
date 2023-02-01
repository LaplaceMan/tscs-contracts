const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
let tscs, zimu, vt, st, access, audit, platform, detection, divide1, onetime0, onetime2;
let tscsAsDeployer, platformAsDeployer;
let owner, user1, user2, user3, user4;
const unitVTAmount = ethers.utils.parseUnits("20", "6");
const baseEthAmount = ethers.utils.parseUnits("60", "ether");
const now = parseInt(Date.now() / 1000 / 86400);
describe("Settlement_OT2_Test", function () {
  it("Prepare", async function () {
    // 获得区块链网络提供的测试账号
    const [deployer, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    deployerAddress = deployer.address;
    owner = deployer;
    user1 = addr1;
    user2 = addr2;
    user3 = addr3;
    user4 = addr4;

    // 部署合约的工厂方法
    const TSCS = await ethers.getContractFactory("Murmes");
    const ZIMU = await ethers.getContractFactory("ZimuToken");
    const VT = await ethers.getContractFactory("VideoToken");
    const ST = await ethers.getContractFactory("SubtitleToken");
    const VAULTANDDEPOSIT = await ethers.getContractFactory("DepositMining");
    const PLATFORM = await ethers.getContractFactory("Platforms");
    const ACCESS = await ethers.getContractFactory("AccessStrategy");
    const AUDIT = await ethers.getContractFactory("AuditStrategy");
    const DETECTION = await ethers.getContractFactory("DetectionStrategy");
    const DIVIDE1 = await ethers.getContractFactory("SettlementDivide1");
    const ONETIME0 = await ethers.getContractFactory("SettlementOneTime0");
    const ONETIME2 = await ethers.getContractFactory("SettlementOneTime2");
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
    platform = await PLATFORM.deploy(tscsAddress);
    const platformAddress = platform.address;
    platformAsDeployer = platform.connect(deployer);
    access = await ACCESS.deploy(tscsAddress);
    const accessAddress = access.address;
    audit = await AUDIT.deploy(tscsAddress, 1);
    const auditAddress = audit.address;
    detection = await DETECTION.deploy(tscsAddress, 5);
    const detectionAddress = detection.address;
    divide1 = await DIVIDE1.deploy(tscsAddress);
    const divide1Address = divide1.address;
    onetime0 = await ONETIME0.deploy(tscsAddress);
    const onetime0Address = onetime0.address;
    onetime2 = await ONETIME2.deploy(tscsAddress);
    const onetime2Address = onetime2.address;
    await tscs.deployed();
    let tx;
    tx = await tscsAsDeployer.setNormalStrategy(0, auditAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setNormalStrategy(1, accessAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setNormalStrategy(2, detectionAddress);
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
    // 注册语言
    tx = await tscsAsDeployer.registerLanguage(['cn', 'us', 'jp']);
    await tx.wait();
    // 添加平台
    await expect(
      platformAsDeployer.platfromJoin(owner.address, "test", "test", 655, 655)
    )
      .to.emit(platform, "PlatformJoin")
      .withArgs(
        owner.address,
        ethers.BigNumber.from("1"),
        "test",
        "test",
        ethers.BigNumber.from("655"),
        ethers.BigNumber.from("655")
      );
    // 创建视频
    await expect(platformAsDeployer.createVideo(1, "test", user1.address, 0))
      .to.emit(platform, "VideoCreate")
      .withArgs(
        owner.address,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("1"),
        "test",
        user1.address,
        ethers.BigNumber.from("0"),
      );
    // 提交申请
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    await expect(
      tscs
        .connect(user1)
        .submitApplication(owner.address, 1, 2, unitVTAmount, 1, date, "test")
    )
      .to.emit(tscs, "ApplicationSubmit")
      .withArgs(
        user1.address,
        owner.address,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("2"),
        unitVTAmount,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from(date),
        ethers.BigNumber.from("1"),
        "test"
      );
    // 上传字幕
    tx = await tscs.connect(user2).uploadSubtitle(1, "test", 1, "0x1a2b");
    await tx.wait();
  });

  it("Despoit for audit", async function () {
    let tx = await zimu.connect(owner).transfer(user3.address, baseEthAmount);
    await tx.wait();
    tx = await zimu.connect(owner).transfer(user4.address, baseEthAmount);
    await tx.wait();
    tx = await zimu
      .connect(user3)
      .approve(tscs.address, baseEthAmount);
    await tx.wait();
    tx = await zimu
      .connect(user4)
      .approve(tscs.address, baseEthAmount);
    await tx.wait();
    tx = await tscs.connect(user3).userJoin(user3.address, baseEthAmount);
    await tx.wait();
    tx = await tscs.connect(user4).userJoin(user4.address, baseEthAmount);
    await tx.wait();
  });

  it("Test adopt subtitle", async function () {
    await expect(tscs.connect(user3).evaluateSubtitle(1, 0))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("1"), user3.address, 0);
    await expect(tscs.connect(user4).evaluateSubtitle(1, 0))
      .to.emit(tscs, "SubitlteGetEvaluation")
      .withArgs(BigNumber.from("1"), user4.address, 0);
  });

  it("Test update counts", async function () {
    // 更新视频播放量
    await expect(platformAsDeployer.updateViewCounts([1], [100000]))
      .to.emit(platform, "VideoCountsUpdate")
      .withArgs(
        owner.address,
        [ethers.BigNumber.from("1")],
        [ethers.BigNumber.from("100000")]
      );
  });

  it("Test pre-extract reward:", async function () {
    let tx = await tscs.connect(user2).preExtractOther("1");
    await tx.wait();
    let user1Reward = await vt.connect(user1).balanceOf(user1.address, 1);
    console.log("User1 get reward:", user1Reward);
    let user2PreRewardState = await tscsAsDeployer.getUserLockReward(
      user2.address,
      owner.address,
      now
    );
    console.log("User2 pre reward state:", user2PreRewardState);
    let user3PreRewardState = await tscsAsDeployer.getUserLockReward(
      user3.address,
      owner.address,
      now
    );
    console.log("User3 pre reward state:", user3PreRewardState);
    let user4PreRewardState = await tscsAsDeployer.getUserLockReward(
      user4.address,
      owner.address,
      now
    );
    console.log("User4 pre reward state:", user4PreRewardState);
  });

  it("Test extract reward:", async function () {
    let tx;
    tx = await tscs.connect(user2).withdraw(owner.address, [now]);
    await tx.wait();
    let user2BalanceNow = await vt.connect(user2).balanceOf(user2.address, 1);
    console.log("User2 get reward:", user2BalanceNow);
    tx = await tscs.connect(user3).withdraw(owner.address, [now]);
    await tx.wait();
    let user3BalanceNow = await vt.connect(user3).balanceOf(user3.address, 1);
    console.log("User3 get reward:", user3BalanceNow);
    tx = await tscs.connect(user4).withdraw(owner.address, [now]);
    await tx.wait();
    let user4BalanceNow = await vt.connect(user4).balanceOf(user4.address, 1);
    console.log("User4 get reward:", user4BalanceNow);
  });
});
