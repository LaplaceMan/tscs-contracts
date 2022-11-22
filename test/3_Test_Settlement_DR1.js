const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
describe("Settlement_DR1_Test", function () {
  let tscs, zimu, vt, st, access, audit, detection, divide1, onetime0, onetime2;
  let tscsAsDeployer;
  let owner, user1, user2, user3, user4;
  const now = parseInt(Date.now() / 1000 / 86400);
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
    const TSCS = await ethers.getContractFactory("SubtitleSystem");
    const ZIMU = await ethers.getContractFactory("ZimuToken");
    const VT = await ethers.getContractFactory("VideoToken");
    const ST = await ethers.getContractFactory("SubtitleToken");
    const VAULT = await ethers.getContractFactory("Vault");
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
    const vault = await VAULT.deploy(deployerAddress, tscsAddress);
    const vaultAddress = vault.address;
    access = await ACCESS.deploy(deployerAddress);
    const accessAddress = access.address;
    audit = await AUDIT.deploy(deployerAddress, 2);
    const auditAddress = audit.address;
    detection = await DETECTION.deploy(deployerAddress, 5);
    const detectionAddress = detection.address;
    divide1 = await DIVIDE1.deploy(tscsAddress);
    const divide1Address = divide1.address;
    onetime0 = await ONETIME0.deploy(tscsAddress);
    const onetime0Address = onetime0.address;
    onetime2 = await ONETIME2.deploy(tscsAddress);
    const onetime2Address = onetime2.address;
    await tscs.deployed();
    let tx;
    tx = await tscsAsDeployer.setAuditStrategy(auditAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setAccessStrategy(accessAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setDetectionStrategy(detectionAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setVault(vaultAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(0, onetime0Address, "OT0");
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(1, divide1Address, "DI1");
    await tx.wait();
    tx = await tscsAsDeployer.setSettlementStrategy(2, onetime2Address, "OTM2");
    await tx.wait();
    tx = await tscsAsDeployer.setZimuToken(zimuAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setVideoToken(vtAddress);
    await tx.wait();
    tx = await tscsAsDeployer.setSubtitleToken(stAddress);
    await tx.wait();
    await zimu.deployed();
    // 注册语言
    tx = await tscsAsDeployer.registerLanguage(["cn", "us", "jp"]);
    await tx.wait();
    // 添加平台
    await expect(
      tscsAsDeployer.platfromJoin(owner.address, "test", "test", 655, 655)
    )
      .to.emit(tscs, "PlatformJoin")
      .withArgs(
        owner.address,
        ethers.BigNumber.from("1"),
        "test",
        "test",
        ethers.BigNumber.from("655"),
        ethers.BigNumber.from("655")
      );
    // 创建视频
    await expect(tscsAsDeployer.createVideo(1, "test", user1.address))
      .to.emit(tscs, "VideoCreate")
      .withArgs(
        owner.address,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("1"),
        "test",
        user1.address
      );
    // 提交申请
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    await expect(
      tscs
        .connect(user1)
        .submitApplication(owner.address, 1, 1, 655, 1, date, "test")
    )
      .to.emit(tscs, "ApplicationSubmit")
      .withArgs(
        user1.address,
        owner.address,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("655"),
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from(date),
        ethers.BigNumber.from("1"),
        "test"
      );
    // 上传字幕
    tx = await tscs.connect(user2).uploadSubtitle(1, "test", 1, "0x1a2b");
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
    await expect(tscsAsDeployer.updateViewCounts([1], [100000]))
      .to.emit(tscs, "VideoCountsUpdate")
      .withArgs(
        owner.address,
        [ethers.BigNumber.from("1")],
        [ethers.BigNumber.from("100000")]
      );
    // 更新字幕使用量
    await expect(tscsAsDeployer.updateUsageCounts([1], [10000]))
      .to.emit(tscs, "SubtitleCountsUpdate")
      .withArgs(
        owner.address,
        [BigNumber.from("1")],
        [BigNumber.from("10000")]
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
