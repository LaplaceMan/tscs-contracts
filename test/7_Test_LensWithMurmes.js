const { ethers } = require("hardhat");
const IModalGlobal_ABI = require("./abis/IModuleGlobals.json");
const MockProfileCreationProxy_ABI = require("./abis/MockProfileCreationProxy.json");
const LensProtocol_ABI = require("./abis/ILensHub.json");
const MockSandboxGovernance_ABI = require("./abis/MockSandboxGovernance.json");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const coder = new ethers.utils.AbiCoder;

let erc20;
let murmes, ptoken, itoken, vault, platforms, component, moduleg, authority, settlement, svm, access, audit, detection, onetime0, divide1, onetime2, authority2, lensModuleForMurmes;
let owner, user1, user2, user3, user4, user5, user6;

let profileId, pubId;

const provider = ethers.provider;
const unitPTAmount = ethers.utils.parseUnits("200", "6");
const baseEthAmount = ethers.utils.parseUnits("60", "ether");
const collectPrice = ethers.utils.parseUnits("1", "ether");

const now = parseInt(Date.now() / 1000 / 86400);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
const ModalGlobal_ADDRESS = "0xcbCC5b9611d22d11403373432642Df9Ef7Dd81AD";
const MockProfileCreationProxy_ADDRESS = "0x4fe8deB1cf6068060dE50aA584C3adf00fbDB87f"
const LENS_ADDRESS = "0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5";
const LENS_GOVERANCE_ADDRESS = "0x1677d9cC4861f1C85ac7009d5F06f49c928CA2AD";
const ModalGlobal = new ethers.Contract(ModalGlobal_ADDRESS, IModalGlobal_ABI, provider);
const MockProfileCreationProxy = new ethers.Contract(MockProfileCreationProxy_ADDRESS, MockProfileCreationProxy_ABI, provider);
const Lens = new ethers.Contract(LENS_ADDRESS, LensProtocol_ABI, provider);
const MockSandboxGovernance = new ethers.Contract(LENS_GOVERANCE_ADDRESS, MockSandboxGovernance_ABI, provider);

describe("Test Murmes With Lens", function () {
    it("Account Prepare", async function () {
        const [deployer, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
        deployerAddress = deployer.address;
        owner = deployer;
        user1 = addr1;
        user2 = addr2;
        user3 = addr3;
        user4 = addr4;
        user5 = addr5;
        user6 = addr6;
    })

    it("Murmes Prepare", async function () {
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

        const AUTHORITY2 = await ethers.getContractFactory("LensAuthority");
        authority2 = await AUTHORITY2.deploy(murmes.address, LENS_ADDRESS);
        tx = await moduleg.connect(owner).setAuthorityModuleIsWhitelisted(authority2.address, "true");
        await tx.wait();

        // 注册条件
        tx = await murmes.connect(owner).registerRequires(['LANG-zh-CN', 'LANG-en-US', 'LANG-ja-JP']);
        await tx.wait();
        // 添加平台
        tx = await platforms.connect(owner).addPlatform(LENS_ADDRESS, "Lens", "Lens", 10000, 100, authority2.address)
        await tx.wait();
    });

    it("Lens Prepare", async function () {
        const LENSMODULEFORMURMES = await ethers.getContractFactory("LensFeeModuleForMurmes");
        lensModuleForMurmes = await LENSMODULEFORMURMES.deploy(LENS_ADDRESS, ModalGlobal_ADDRESS, murmes.address);
        /*****************/
        const setModuleWhitelisted = await MockSandboxGovernance.connect(owner).whitelistCollectModule(lensModuleForMurmes.address, true);
        await setModuleWhitelisted.wait();
        const setCurrencyWhitelisted = await ModalGlobal.connect(owner).whitelistCurrency(erc20.address, true);
        await setCurrencyWhitelisted.wait();
    })

    it("Murmes Module Prepare", async function () {
        const setLensMoudle = await authority2.connect(owner).setWhitelistedLensModule(lensModuleForMurmes.address, true);
        await setLensMoudle.wait();
    })

    it("Lens Create Publication", async function () {
        const createProfile = await MockProfileCreationProxy.connect(user1).proxyCreateProfile([user1.address, "murmesmu", "", ZERO_ADDRESS, "0x", ""])
        await createProfile.wait();
        profileId = await Lens.getProfileIdByHandle("murmesmu.test");
        const setData = coder.encode(["uint256", "address", "address", "uint16", "bool"], [collectPrice, erc20.address, user1.address, "0", false]);
        const createPub = await Lens.connect(user1).post([profileId, "ipfs//something", lensModuleForMurmes.address, setData, ZERO_ADDRESS, "0x"]);
        await createPub.wait();
    })

    it("Post Task", async function () {
        pubId = await Lens.connect(owner).getPubCount(profileId);
        const profileIdString = BigNumber.from(profileId).toString()
        const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
        const tx = await murmes.connect(user1).postTask([LENS_ADDRESS, pubId, 1, profileIdString, 1, 100, ZERO_ADDRESS, audit.address, detection.address, date]);
        await tx.wait();
    })

    it("Submit Item", async function () {
        const tx = await murmes.connect(user2).submitItem([1, "item", 1, "0x1a"]);
        await tx.wait();
    })

    it("Deposit for Audit", async function () {
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
        let taskState = await murmes.connect(owner).getAdoptedItemData(1);
        console.log("Task state:", taskState);
    });

    it("Collect Publication", async function () {
        let tx;
        tx = await erc20.connect(owner).mint(owner.address, baseEthAmount);
        await tx.wait();
        tx = await erc20
            .connect(owner)
            .approve(lensModuleForMurmes.address, baseEthAmount);
        await tx.wait();
        const setData = coder.encode(["address", "uint256"], [erc20.address, collectPrice]);
        const collectPub = await Lens.connect(owner).collect(profileId, pubId, setData);
        await collectPub.wait();
    })

    it("Update Revenue", async function () {
        const updateRevenue = await platforms.connect(user1).updateBoxesRevenue([1], [0]);
        await updateRevenue.wait();
    });

    it("Pre-extract Revenue:", async function () {
        let tx = await settlement.connect(user2).preExtractForOther("1");
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
        /*************************/
        let user1Revenue = await ptoken.connect(owner).balanceOf(user1.address, 1);
        console.log('Box creator revenue:', user1Revenue);
        /*************************/
        let user2PreRevenueState = await murmes.connect(owner).getUserLockReward(
            user2.address,
            LENS_ADDRESS,
            now
        );
        console.log("User2 pre revenue state:", user2PreRevenueState);
        let user3PreRevenueState = await murmes.connect(owner).getUserLockReward(
            user3.address,
            LENS_ADDRESS,
            now
        );
        console.log("User3 pre revenue state:", user3PreRevenueState);
        let user4PreRevenueState = await murmes.connect(owner).getUserLockReward(
            user4.address,
            LENS_ADDRESS,
            now
        );
        console.log("User4 pre revenue state:", user4PreRevenueState);
    });

    it("Extract Revenue:", async function () {
        let tx;
        /*************************/
        tx = await murmes.connect(user2).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user2BalanceNow = await ptoken.connect(owner).balanceOf(user2.address, 1);
        console.log("User2 get revenue:", user2BalanceNow);
        /*************************/
        tx = await murmes.connect(user3).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user3BalanceNow = await ptoken.connect(user3).balanceOf(user3.address, 1);
        console.log("User3 get revenue:", user3BalanceNow);
        tx = await murmes.connect(user4).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user4BalanceNow = await ptoken.connect(user4).balanceOf(user4.address, 1);
        console.log("User4 get revenue:", user4BalanceNow);
    });

    it("Swap Token", async function () {
        const approve = await ptoken.connect(user1).setApprovalForAll(authority2.address, true);
        await approve.wait();
        const beforeBalance = await erc20.connect(owner).balanceOf(user1.address);
        console.log("beforeBalance: ", beforeBalance);
        const swap = await authority2.connect(user1).swap(unitPTAmount);
        await swap.wait();
        const afterBalance = await erc20.connect(owner).balanceOf(user1.address);
        console.log("afterBalance: ", afterBalance);
    })
});

