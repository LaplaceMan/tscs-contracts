const { expect } = require("chai");
const { ethers } = require("hardhat");
const { AddressZero } = require("@ethersproject/constants");
describe("MainSystem_Test", function () {
  let tscs, zimu, vt, st, access, audit, detection, divide1, onetime0, onetime2;
  let tscsAsDeployer;
  let owner, user1, user2, user3;
  const baseEthAmount = ethers.utils.parseUnits("60", "ether");
  const unitEthAmount = ethers.utils.parseUnits("20", "ether");
  it("Deploy contracts", async function () {
    // beforeEach(async function () {
    // 获得区块链网络提供的测试账号
    const [deployer, addr1, addr2, addr3] = await ethers.getSigners();
    deployerAddress = deployer.address;
    owner = deployer;
    user1 = addr1;
    user2 = addr2;
    user3 = addr3;

    // 部署合约的工厂方法
    const TSCS = await ethers.getContractFactory("SubtitleSystem");
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
    await tscs.deployed();
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
    // console.log("\n");
    // console.log("setAuditStrategy", tx1);
    // console.log("setAccessStrategy", tx2);
    // console.log("setDetectionStrategy", tx3);
    // console.log("setSettlementStrategy0", tx4);
    // console.log("setSettlementStrategy1", tx5);
    // console.log("setSettlementStrategy2", tx6);
    // console.log("setZimuToken", tx7);
    // console.log("setVideoToken", tx8);
    // console.log("setSubtitleToken", tx9);
  });

  it("Test Zimu transfer", async function () {
    await zimu.deployed();
    const balanceUser1old = await zimu.connect(user1).balanceOf(user1.address);
    console.log("User1 Zimu balance before transfer is", balanceUser1old);
    await zimu.connect(owner).transfer(user1.address, baseEthAmount);
    const balanceUser1new = await zimu.connect(user1).balanceOf(user1.address);
    console.log("User1 Zimu balance after transfer is", balanceUser1new);
    expect(balanceUser1new).to.equal(baseEthAmount);
  });

  it("Test user join", async function () {
    await zimu.connect(user1).approve(tscs.address, baseEthAmount);
    const user1Approved = await zimu
      .connect(user1)
      .allowance(user1.address, tscs.address);
    console.log("User1-TSCS Zimu approved amount:", user1Approved);
    expect(user1Approved).to.equal(baseEthAmount);
    await expect(tscs.connect(user1).userJoin(user1.address, unitEthAmount))
      .to.emit(tscs, "UserJoin")
      .withArgs(user1.address, ethers.BigNumber.from("1000"), unitEthAmount);
    let user1JoinInfo = await tscs
      .connect(user1)
      .getUserBaseInfo(user1.address);
    console.log("User joined info:", user1JoinInfo);
  });

  it("Test add language", async function () {
    await tscsAsDeployer.registerLanguage(["cn", "en", "jp"]);
    let cnIndex = await tscsAsDeployer.getLanguageId("cn");
    let enIndex = await tscsAsDeployer.getLanguageId("en");
    let jpIndex = await tscsAsDeployer.getLanguageId("jp");
    expect(cnIndex).to.equal(1);
    expect(enIndex).to.equal(2);
    expect(jpIndex).to.equal(3);
  });

  it("Test submit application (OT0)", async function () {
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    let tx = await tscs
      .connect(user1)
      .submitApplication(AddressZero, 0, 0, unitEthAmount, 1, date, "test");
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
  });

  it("Test upload subtitle", async function () {
    let tx = await tscs.connect(user2).uploadSubtitle(1, "test", 1, "0x1a2b");
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
  });

  it("Test evaluate (audit) subtitle", async function () {
    let tx = await tscs.connect(user3).evaluateSubtitle(1, 0);
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
  });

  it("Test add platform", async function () {
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
  });

  it("Test platform add (create) video", async function () {
    await expect(tscsAsDeployer.createVideo(1, "test", user1.address, 0))
      .to.emit(tscs, "VideoCreate")
      .withArgs(
        owner.address,
        ethers.BigNumber.from("1"),
        ethers.BigNumber.from("1"),
        "test",
        user1.address,
        ethers.BigNumber.from("0")
      );
  });

  it("Test platform update counts", async function () {
    await expect(tscsAsDeployer.updateViewCounts([1], [10000]))
      .to.emit(tscs, "VideoCountsUpdate")
      .withArgs(
        owner.address,
        [ethers.BigNumber.from("1")],
        [ethers.BigNumber.from("10000")]
      );
  });

  it("Test submit application (other)", async function () {
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
        ethers.BigNumber.from("2"),
        "test"
      );
  });
});
