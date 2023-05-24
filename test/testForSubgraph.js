const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

let erc20;
let murmes, ptoken, itoken, vault, platforms, component, moduleg, authority, settlement, access, audit, detection, onetime0, divide1, onetime2, authority1;
let owner, user1, user2, user3, user4, user5;

const baseEthAmount = ethers.utils.parseUnits("100", "ether");
const unitEthAmount = ethers.utils.parseUnits("32", "ether");
const unitPlatformToken = ethers.utils.parseUnits("50", "6");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const now = parseInt(Date.now() / 1000 / 86400);

describe("Settlement_MIX_Test", function () {
  it("Prepare", async function () {
    // 获得区块链网络提供的测试账号
    const [deployer, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    owner = deployer;
    user1 = addr1;
    user2 = addr2;
    user3 = addr3;
    user4 = addr4;
    user5 = addr5;

    // 部署合约的工厂方法
    const MURMES = await ethers.getContractFactory("Murmes");
    // 组件
    const PT = await ethers.getContractFactory("PlatformToken");
    const IT = await ethers.getContractFactory("ItemToken");
    const VAULT = await ethers.getContractFactory("Vault");
    const PLATFORMS = await ethers.getContractFactory("Platforms");
    const COMPONENT = await ethers.getContractFactory("ComponentGlobal");
    const MODULE = await ethers.getContractFactory("ModuleGlobal");
    const SETTLEMENT = await ethers.getContractFactory("Settlement")
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

    // 部署合约
    murmes = await MURMES.deploy(owner.address, owner.address);
    // 辅助
    erc20 = await ERC20.deploy();
    const AUTHORITY0 = await ethers.getContractFactory("MurmesAuthority");
    const authority0 = await AUTHORITY0.deploy();
    // 组件
    ptoken = await PT.deploy(murmes.address);
    itoken = await IT.deploy(murmes.address);
    vault = await VAULT.deploy(murmes.address, owner.address);
    platforms = await PLATFORMS.deploy(murmes.address, authority0.address);
    component = await COMPONENT.deploy(murmes.address, erc20.address);
    moduleg = await MODULE.deploy(murmes.address);
    settlement = await SETTLEMENT.deploy(murmes.address)
    const svm = await SVM.deploy(murmes.address);
    // 模块
    authority = await AUTHORITY.deploy(murmes.address);
    access = await ACCESS.deploy(murmes.address);
    audit = await AUDIT.deploy(murmes.address, 1, "DEFAULT_MAJORITY");
    detection = await DETECTION.deploy(murmes.address, 5, "DEFAULT_HAMMING");
    onetime0 = await ONETIME0.deploy(murmes.address);
    divide1 = await DIVIDE1.deploy(murmes.address);
    onetime2 = await ONETIME2.deploy(murmes.address);

    // 打印部署合约的地址
    console.log("Murmes Contract:", murmes.address);
    console.log("Platform Token Contract:", ptoken.address);
    console.log("Item Token Contract:", itoken.address);
    console.log("Vault Contract:", vault.address);
    console.log("Platforms Contract:", platforms.address);
    console.log("Component Global Contract:", component.address);
    console.log("Module Global Contract:", moduleg.address);
    console.log("Settlement Contract:", settlement.address);
    console.log("Authority Contract:", authority.address);
    console.log("Access Contract:", access.address);
    console.log("Audit Contract:", audit.address);
    console.log("Detection Contract:", detection.address);
    console.log("Settlement OT0 Contract:", onetime0.address);
    console.log("Settlement D1 Contract:", divide1.address);
    console.log("Settlement OT2 Contract:", onetime2.address);
    console.log("Version Management Contract:", svm.address);

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
    // 添加平台
    tx = await platforms.connect(owner).addPlatform(owner.address, "platform", "platform", 100, 100, authority1.address)
    await tx.wait();
    // 创建Box
    tx = await platforms.connect(owner).createBox(1, owner.address, user1.address);
    await tx.wait();
    /*************************/
    // 提交申请(OT2)
    const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
    tx = await murmes.connect(user1).postTask([owner.address, 1, 1, "source", 2, unitPlatformToken, ZERO_ADDRESS, audit.address, detection.address, date]);
    await tx.wait();
    // 上传Item
    tx = await murmes.connect(user2).submitItem([1, "item", 1, "0x1a"]);
    await tx.wait();
    /*************************/
    // 提交申请(D1)
    tx = await murmes.connect(user1).postTask([owner.address, 1, 2, "source", 1, 100, ZERO_ADDRESS, audit.address, detection.address, date]);
    await tx.wait();
    // 上传Item
    tx = await murmes.connect(user3).submitItem([2, "item", 2, "0x1a2b"]);
    await tx.wait();
  });

  it("Audit Item", async function () {
    let tx;
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
    tx = await murmes.connect(user4).auditItem(1, 0);
    await tx.wait();
    tx = await murmes.connect(user5).auditItem(1, 0);
    await tx.wait();
    /*************************/
    tx = await murmes.connect(user4).auditItem(2, 0);
    await tx.wait();
    tx = await murmes.connect(user5).auditItem(2, 0);
    await tx.wait();
  });

  it("Update Box Revenue", async function () {
    let tx = await platforms.connect(owner).updateBoxesRevenue([1], [10000]);
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
  });

  it("Pre-extract Revenue", async function () {
    let tx = await settlement.connect(user2).preExtractForOther("1");
    await tx.wait();
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
  });

  it("Extract Revenue", async function () {
    let tx;
    /*************************/
    tx = await murmes.connect(user2).withdraw(owner.address, [now]);
    await tx.wait();
    tx = await murmes.connect(user3).withdraw(owner.address, [now]);
    await tx.wait();
    /*************************/
    tx = await murmes.connect(user4).withdraw(owner.address, [now]);
    await tx.wait();
    tx = await murmes.connect(user5).withdraw(owner.address, [now]);
    await tx.wait();
  });
});
