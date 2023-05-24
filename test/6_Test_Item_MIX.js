const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

let erc20;
let murmes, ptoken, itoken, vault, platforms, component, moduleg, authority, settlement, svm, access, audit, detection, onetime0, divide1, onetime2, authority1;
let owner, user1, user2, user3, user4, user5, user6;

const baseEthAmount = ethers.utils.parseUnits("100", "ether");
const unitEthAmount = ethers.utils.parseUnits("32", "ether");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("Item_Realted_Test", function () {
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

    // 部署合约的工厂方法
    const MURMES = await ethers.getContractFactory("Murmes");
    // 组件
    const PT = await ethers.getContractFactory("PlatformToken");
    const IT = await ethers.getContractFactory("ItemToken");
    const VAULT = await ethers.getContractFactory("Vault");
    const PLATFORMS = await ethers.getContractFactory("Platforms");
    const COMPONENT = await ethers.getContractFactory("ComponentGlobal");
    const MODULE = await ethers.getContractFactory("ModuleGlobal");
    const SETTLEMENT = await ethers.getContractFactory("Settlement");
    const SVM = await ethers.getContractFactory("ItemVersionManagement");
    // 模块
    const ACCESS = await ethers.getContractFactory("AccessModule");
    const AUDIT = await ethers.getContractFactory("AuditModule");
    const AUTHORITY = await ethers.getContractFactory("AuthorityModule");
    const DETECTION = await ethers.getContractFactory("DetectionModule");
    const ONETIME0 = await ethers.getContractFactory
      ("SettlementOneTime0");
    const DIVIDE1 = await ethers.getContractFactory
      ("SettlementDivide1");
    const ONETIME2 = await ethers.getContractFactory
      ("SettlementOneTime2");
    // 辅助
    const ERC20 = await ethers.getContractFactory("ERC20Mintable");
    const AUTHORITY0 = await ethers.getContractFactory("MurmesAuthority");
    const authority0 = await AUTHORITY0.deploy();
    // 部署合约
    murmes = await MURMES.deploy(owner.address, owner.address);
    // 辅助
    erc20 = await ERC20.deploy();
    // 组件
    ptoken = await PT.deploy(murmes.address);
    itoken = await IT.deploy(murmes.address);
    vault = await VAULT.deploy(murmes.address, owner.address);
    platforms = await PLATFORMS.deploy(murmes.address, authority0.address);
    component = await COMPONENT.deploy(murmes.address, erc20.address);
    moduleg = await MODULE.deploy(murmes.address);
    settlement = await SETTLEMENT.deploy(murmes.address)
    svm = await SVM.deploy(murmes.address);
    // 模块
    authority = await AUTHORITY.deploy(murmes.address);
    access = await ACCESS.deploy(murmes.address);
    audit = await AUDIT.deploy(murmes.address, 1, "DEFAULT_MAJORITY");
    detection = await DETECTION.deploy(murmes.address, 5, "DEFAULT_HAMMING");
    onetime0 = await ONETIME0.deploy(murmes.address);
    divide1 = await DIVIDE1.deploy(murmes.address);
    onetime2 = await ONETIME2.deploy(murmes.address);

    let tx;
    // 组件
    tx = await murmes.connect(owner).setGlobalContract(0, moduleg.address);
    await tx.wait();
    tx = await murmes.connect(owner).setGlobalContract(1, component.address);
    tx = await component.connect(owner).setComponent(0, vault.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(1, access.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(2, svm.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(3, platforms.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(4, settlement.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(5, authority.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(7, itoken.address);
    await tx.wait();
    tx = await component.connect(owner).setComponent(8, ptoken.address);
    await tx.wait();
    // 模块
    tx = await moduleg.connect(owner).setSettlementModule(0, onetime0.address);
    await tx.wait();
    tx = await moduleg.connect(owner).setSettlementModule(1, divide1.address);
    await tx.wait();
    tx = await moduleg.connect(owner).setSettlementModule(2, onetime2.address);
    await tx.wait();
    tx = await moduleg.connect(owner).setWhitelistedCurrency(erc20.address, "true");
    await tx.wait();
    tx = await moduleg.connect(owner).setWhitelistedAuditModule(audit.address, "true");
    await tx.wait();
    tx = await moduleg.connect(owner).setDetectionModuleIsWhitelisted(detection.address, "true");
    await tx.wait();

    const AUTHORITY1 = await ethers.getContractFactory("DefaultAuthority");
    authority1 = await AUTHORITY1.deploy(murmes.address);
    tx = await moduleg.connect(owner).setAuthorityModuleIsWhitelisted(authority1.address, "true");
    await tx.wait();

    // 注册条件
    tx = await murmes.connect(owner).registerRequires(['LANG-zh-CN', 'LANG-en-US', 'LANG-ja-JP']);
    await tx.wait();
    // 铸造ERC20代币
    tx = await erc20.connect(user1).mint(user1.address, baseEthAmount);
    await tx.wait();
    tx = await erc20
      .connect(user1)
      .approve(murmes.address, baseEthAmount);
    await tx.wait();
    tx = await murmes.connect(user1).userJoin(user1.address, unitEthAmount);
    await tx.wait();
    // 提交申请
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    tx = await murmes
      .connect(user1)
      .postTask([murmes.address, 0, 1, "source", 0, unitEthAmount, erc20.address, audit.address, detection.address, date]);
    await tx.wait();
  });

  it("Upload Items", async () => {
    tx = await murmes.connect(user2).submitItem([1, "item1", 1, "0x1a"]);
    await tx.wait();
    tx = await murmes.connect(user3).submitItem([1, "item2", 1, "0x1a2b"]);
    await tx.wait();
  })

  it("Update Items", async () => {
    // 更新字幕版本
    let tx;
    tx = await svm.connect(user2).updateItemVersion(1, "0x1a2a", "1item1")
    await tx.wait();
    tx = await svm.connect(user3).updateItemVersion(2, "0x2a2b", "2item2")
    await tx.wait();
  })

  it("User Join", async function () {
    let tx;
    /*************************/
    tx = await erc20.connect(user4).mint(user4.address, baseEthAmount);
    await tx.wait();
    tx = await erc20
      .connect(user4)
      .approve(murmes.address, baseEthAmount);
    await tx.wait();
    tx = await murmes.connect(user4).userJoin(user4.address, baseEthAmount);
    await tx.wait();
    /*************************/
    tx = await erc20.connect(user5).mint(user5.address, baseEthAmount);
    await tx.wait();
    tx = await erc20
      .connect(user5)
      .approve(murmes.address, baseEthAmount);
    await tx.wait();
    tx = await murmes.connect(user5).userJoin(user5.address, baseEthAmount);
    await tx.wait();
    /*************************/
    tx = await erc20.connect(user6).mint(user6.address, baseEthAmount);
    await tx.wait();
    tx = await erc20
      .connect(user6)
      .approve(murmes.address, baseEthAmount);
    await tx.wait();
    tx = await murmes.connect(user6).userJoin(user6.address, baseEthAmount);
    await tx.wait();
  });

  it("Audit Items (Deleted Item)", async function () {
    let tx;
    // 给恶意Item好评
    tx = await murmes.connect(user6).auditItem(1, 0);
    await tx.wait();
    // 举报恶意Item
    tx = await murmes.connect(user4).auditItem(1, 1);
    await tx.wait();
    tx = await murmes.connect(user5).auditItem(1, 1);
    await tx.wait();
    /*************************/
    let item1AuditState = await murmes.connect(owner).getItem(1);
    console.log("Item1 audit state:", item1AuditState);
    /*************************/
    let item1OwnerInfo = await murmes.connect(owner).getUserBaseData(user2.address);
    console.log("AFTER:Deleted item's evil maker Info", item1OwnerInfo);
    let itemSuppoterInfo = await murmes.connect(owner).getUserBaseData(user6.address);
    console.log("AFTER:Deleted item's evil Info", itemSuppoterInfo);
    let itemRepoterInfo = await murmes.connect(owner).getUserBaseData(user4.address);
    console.log("AFTER:Deleted item's normal Info", itemRepoterInfo);
  })

  it("Audit Items (Adopted Item)", async function () {
    let tx;
    // 举报正常Item
    tx = await murmes.connect(user6).auditItem(2, 1);
    await tx.wait();
    // 给正常Item好评
    tx = await murmes.connect(user4).auditItem(2, 0);
    await tx.wait();
    tx = await murmes.connect(user5).auditItem(2, 0);
    await tx.wait();
    /*************************/
    let item1AuditState = await murmes.connect(owner).getItem(2);
    console.log("Item2 audit state:", item1AuditState);
    /*************************/
    let item2OwnerInfo = await murmes.connect(owner).getUserBaseData(user3.address);
    console.log("AFTER:Adoptd item's maker Info", item2OwnerInfo);
    let itemRepoterInfo = await murmes.connect(owner).getUserBaseData(user6.address);
    console.log("AFTER:Adoptd item's evil Info", itemRepoterInfo);
    let itemSuppoterInfo = await murmes.connect(owner).getUserBaseData(user4.address);
    console.log("AFTER:Adoptd item's normal Info", itemSuppoterInfo);
  });

  it("Delete Invaild Item Versions", async function () {
    let vaildVersion = await svm.connect(owner).getLatestValidVersion(1);
    console.log("Evil item vaild version:", vaildVersion);
    let tx = await svm.connect(owner).deleteInvaildItem(1);
    tx.wait();
    vaildVersion = await svm.connect(owner).getLatestValidVersion(1);
    console.log("Latest evil item vaild version:", vaildVersion);
  });
});
