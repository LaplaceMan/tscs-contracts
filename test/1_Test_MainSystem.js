const { expect } = require("chai");
const { ethers } = require("hardhat");

let erc20;
let murmes, ptoken, itoken, vault, platforms, component, moduleg, authority, settlement, access, audit, detection, onetime0, divide1, onetime2, authority1;
let owner, user1, user2, user3, user4, user5;

const baseEthAmount = ethers.utils.parseUnits("100", "ether");
const unitEthAmount = ethers.utils.parseUnits("32", "ether");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("Murmes_Base_Test", function () {
    it("Deploy Contracts", async function () {
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
        // 组件
        ptoken = await PT.deploy(murmes.address);
        itoken = await IT.deploy(murmes.address);
        vault = await VAULT.deploy(murmes.address, owner.address);
        platforms = await PLATFORMS.deploy(murmes.address);
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

        const AUTHORITY0 = await ethers.getContractFactory("MurmesAuthority");
        const authority0 = await AUTHORITY0.deploy();
        tx = await platforms.connect(owner).setMurmesAuthorityModule(authority0.address);
        await tx.wait();
        const AUTHORITY1 = await ethers.getContractFactory("DefaultAuthority");
        authority1 = await AUTHORITY1.deploy(murmes.address);
        tx = await moduleg.connect(owner).setAuthorityModuleIsWhitelisted(authority1.address, "true");
        await tx.wait();
    });

    it("User Join", async function () {
        let tx;
        tx = await erc20.connect(user1).mint(user1.address, baseEthAmount);
        await tx.wait();
        tx = await erc20
            .connect(user1)
            .approve(murmes.address, baseEthAmount);
        await tx.wait();
        tx = await murmes.connect(user1).userJoin(user1.address, unitEthAmount);
        await tx.wait();
        let user1JoinInfo = await murmes
            .connect(user1)
            .getUserBaseData(user1.address);
        console.log("User joined info:", user1JoinInfo);
    });

    it("Add Requires", async function () {
        let tx = await murmes.connect(owner).registerRequires(['LANG-zh-CN', 'LANG-en-US', 'LANG-ja-JP']);
        await tx.wait();
        let cnIndex = await murmes.connect(owner).getRequiresIdByNote('LANG-zh-CN');
        let enIndex = await murmes.connect(owner).getRequiresIdByNote('LANG-en-US');
        let jpIndex = await murmes.connect(owner).getRequiresIdByNote('LANG-ja-JP');
        expect(cnIndex).to.equal(1);
        expect(enIndex).to.equal(2);
        expect(jpIndex).to.equal(3);
    });

    it("Post Task (OT0)", async function () {
        const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
        let tx = await murmes
            .connect(user1)
            .postTask([murmes.address, 0, 1, "source", 0, unitEthAmount, erc20.address, audit.address, detection.address, date]);
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Upload Items", async function () {
        let tx;
        tx = await murmes.connect(user2).submitItem([1, "item", 1, "0x1a"]);
        await tx.wait();
        tx = await murmes.connect(user2).submitItem([1, "item", 1, "0x1a2b"]);
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Audit Items", async function () {
        let tx;
        tx = await erc20.connect(user4).mint(user4.address, baseEthAmount);
        await tx.wait();
        tx = await erc20
            .connect(user4)
            .approve(murmes.address, baseEthAmount);
        await tx.wait();
        tx = await murmes.connect(user4).userJoin(user4.address, baseEthAmount);
        await tx.wait();
        tx = await murmes.connect(user4).auditItem(1, 0);
        await tx.wait();
        tx = await murmes.connect(user4).auditItem(2, 1);
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });
});

describe("Murmes_Other_Test", function () {
    it("Add platform", async function () {
        let tx = await platforms.connect(owner).addPlatform(owner.address, "platform", "platform", 100, 100, authority1.address)
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Create Box", async function () {
        let tx = await platforms.connect(owner).createBox(1, owner.address, user1.address);
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Update Box Revenue", async function () {
        let tx = await platforms.connect(owner).updateBoxesRevenue([1], [10000]);
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Post Task (Other)", async function () {
        const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
        let tx = await murmes.connect(user1).postTask([owner.address, 1, 2, "source", 1, 100, ZERO_ADDRESS, audit.address, detection.address, date]);
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });
});