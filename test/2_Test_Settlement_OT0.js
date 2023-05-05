const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

let erc20;
let murmes, ptoken, itoken, vault, platforms, component, moduleg, authority, settlement, access, audit, detection, onetime0, divide1, onetime2, authority1;
let owner, user1, user2, user3, user4, user5;

const baseEthAmount = ethers.utils.parseUnits("100", "ether");
const unitEthAmount = ethers.utils.parseUnits("32", "ether");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const now = parseInt(Date.now() / 1000 / 86400);

describe("Settlement_OT0_Test", function () {
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
    const SETTLEMENT = await ethers.getContractFactory("Settlement");
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
    // 模块
    authority = await AUTHORITY.deploy(murmes.address);
    access = await ACCESS.deploy(murmes.address);
    audit = await AUDIT.deploy(murmes.address, 1);
    detection = await DETECTION.deploy(murmes.address, 5);
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
    // 上传 Item
    tx = await murmes.connect(user2).submitItem([1, "item", 1, "0x1a"]);
    await tx.wait();
  });

  it("Audit Item", async function () {
    let tx;
    tx = await erc20.connect(user3).mint(user3.address, baseEthAmount);
    await tx.wait();
    tx = await erc20
      .connect(user3)
      .approve(murmes.address, baseEthAmount);
    await tx.wait();
    tx = await murmes.connect(user3).userJoin(user3.address, baseEthAmount);
    await tx.wait();
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
    tx = await murmes.connect(user3).auditItem(1, 0);
    await tx.wait();
    tx = await murmes.connect(user4).auditItem(1, 0);
    await tx.wait();
    /*************************/
    // let itemState = await murmes.connect(owner).getItem(1);
    // console.log("Item state:", itemState);
    // let taskState = await murmes.connect(owner).getAdoptedItemData(1);
    // console.log("Task state:", taskState);
  });

  it("Pre-extract Revenue", async function () {
    let tx = await settlement.connect(user2).preExtractForNormal("1");
    await tx.wait();
    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    expect(receipt.status).to.equal(1);
    /*************************/
    let user2PreRevenueState = await murmes.connect(owner).getUserLockReward(
      user2.address,
      erc20.address,
      now
    );
    console.log("User2 pre revenue state:", user2PreRevenueState);
    let user3PreRevenueState = await murmes.connect(owner).getUserLockReward(
      user3.address,
      erc20.address,
      now
    );
    console.log("User3 pre revenue state:", user3PreRevenueState);
    let user4PreRevenueState = await murmes.connect(owner).getUserLockReward(
      user4.address,
      erc20.address,
      now
    );
    console.log("User4 pre revenue state:", user4PreRevenueState);
  });

  it("Extract Revenue", async function () {
    let tx;
    /*************************/
    tx = await murmes.connect(user2).withdraw(erc20.address, [now]);
    await tx.wait();
    let user2BalanceNow = await erc20.connect(owner).balanceOf(user2.address);
    console.log("User2 get revenue:", user2BalanceNow);
    /*************************/
    tx = await murmes.connect(user3).withdraw(erc20.address, [now]);
    await tx.wait();
    let user3BalanceNow = await erc20.connect(user3).balanceOf(user3.address);
    console.log("User3 get revenue:", user3BalanceNow);
    tx = await murmes.connect(user4).withdraw(erc20.address, [now]);
    await tx.wait();
    let user4BalanceNow = await erc20.connect(user4).balanceOf(user4.address);
    console.log("User4 get revenue:", user4BalanceNow);
  });
});
