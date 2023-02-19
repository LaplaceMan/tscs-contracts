const { ethers } = require("hardhat");
const IModalGlobal_ABI = require("./abis/IModuleGlobals.json");
const MockProfileCreationProxy_ABI = require("./abis/MockProfileCreationProxy.json");
const LensProtocol_ABI = require("./abis/ILensHub.json");
const MockSandboxGovernance_ABI = require("./abis/MockSandboxGovernance.json");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const coder = new ethers.utils.AbiCoder;

let tscs, zimu, vt, st, access, audit, authority, platform, detection, divide1, onetime0, onetime2, lensModuleForMurmes;
let deployerAddress;
let tscsAsDeployer, platformAsDeployer;
let owner, user1, user2, user3, user4;

let profileId, pubId;

const provider = ethers.provider;
const unitVTAmount = ethers.utils.parseUnits("20", "6");
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
        const [deployer, addr1, addr2, addr3, addr4] = await ethers.getSigners();
        deployerAddress = deployer.address;
        owner = deployer;
        user1 = addr1;
        user2 = addr2;
        user3 = addr3;
        user4 = addr4;
    })

    it("Murmes Prepare", async function () {
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
        const LENSMODULEFORMURMES = await ethers.getContractFactory("LensFeeModuleForMurmes");
        // 部署合约
        tscs = await TSCS.deploy(deployerAddress, deployerAddress);
        const tscsAddress = tscs.address;
        tscsAsDeployer = tscs.connect(owner);
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
        platformAsDeployer = platform.connect(owner);
        access = await ACCESS.deploy(tscsAddress);
        const accessAddress = access.address;
        audit = await AUDIT.deploy(tscsAddress, 1);
        const auditAddress = audit.address;
        authority = await AUTHORITY.deploy(tscsAddress, LENS_ADDRESS);
        const authorityAddress = await authority.address;
        detection = await DETECTION.deploy(tscsAddress, 5);
        const detectionAddress = detection.address;
        divide1 = await DIVIDE1.deploy(tscsAddress);
        const divide1Address = divide1.address;
        onetime0 = await ONETIME0.deploy(tscsAddress);
        const onetime0Address = onetime0.address;
        onetime2 = await ONETIME2.deploy(tscsAddress);
        const onetime2Address = onetime2.address;
        lensModuleForMurmes = await LENSMODULEFORMURMES.deploy(LENS_ADDRESS, ModalGlobal_ADDRESS, tscsAddress);
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
        // 注册语言
        tx = await tscsAsDeployer.registerLanguage(['zh-CN', 'en-US', 'ja-JP']);
        await tx.wait();
        // 添加平台
        tx = await platformAsDeployer.platfromJoin(LENS_ADDRESS, "Lens Protocol", "Lens", 65535, 655)
        await tx.wait();
    });

    it("Lens Prepare", async function () {
        const setModuleWhitelisted = await MockSandboxGovernance.connect(owner).whitelistCollectModule(lensModuleForMurmes.address, true);
        await setModuleWhitelisted.wait();
        const setCurrencyWhitelisted = await ModalGlobal.connect(owner).whitelistCurrency(zimu.address, true);
        await setCurrencyWhitelisted.wait();
    })

    it("Murmes Module Prepare", async function () {
        const setLensMoudle = await authority.connect(owner).setWhitelistedLensModule(lensModuleForMurmes.address, true);
        await setLensMoudle.wait();
    })

    it("Lens Create Publication", async function () {
        const createProfile = await MockProfileCreationProxy.connect(user1).proxyCreateProfile([user1.address, "murmesmu", "", ZERO_ADDRESS, "0x", ""])
        await createProfile.wait();
        profileId = await Lens.getProfileIdByHandle("murmesmu.test");
        const setData = coder.encode(["uint256", "address", "address", "uint16", "bool"], [collectPrice, zimu.address, user1.address, "0", false]);
        const createPub = await Lens.connect(user1).post([profileId, "ipfs//something", lensModuleForMurmes.address, setData, ZERO_ADDRESS, "0x"]);
        await createPub.wait();
    })

    it("Submit Application", async function () {
        pubId = await Lens.connect(owner).getPubCount(profileId);
        const profileIdString = BigNumber.from(profileId).toString()
        const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
        const submitApplication = await tscs.connect(user1).submitApplication(LENS_ADDRESS, pubId, 1, 655, 1, date, profileIdString);
        await submitApplication.wait();
    })

    it("Upload Subtitle", async function () {
        const uploadSubtitle = await tscs.connect(user2).uploadSubtitle(1, "test", 1, "0x1a2b");
        await uploadSubtitle.wait();
    })

    it("Despoit for Audit", async function () {
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

    it("Adopt the Subtitle", async function () {
        await expect(tscs.connect(user3).evaluateSubtitle(1, 0))
            .to.emit(tscs, "SubitlteGetEvaluation")
            .withArgs(BigNumber.from("1"), user3.address, 0);
        await expect(tscs.connect(user4).evaluateSubtitle(1, 0))
            .to.emit(tscs, "SubitlteGetEvaluation")
            .withArgs(BigNumber.from("1"), user4.address, 0);
    });

    it("Collect Publication", async function () {
        const approve = await zimu.connect(owner).approve(lensModuleForMurmes.address, baseEthAmount)
        await approve.wait();
        const setData = coder.encode(["address", "uint256"], [zimu.address, collectPrice]);
        const collectPub = await Lens.connect(owner).collect(profileId, pubId, setData);
        await collectPub.wait();
    })

    it("Update Revenue", async function () {
        const updateRevenue = await platform.connect(user1).updateViewCounts([1], [0]);
        await updateRevenue.wait();
    });

    it("Pre-extract Reward:", async function () {
        let tx = await tscs.connect(user1).preExtractOther("1");
        await tx.wait();
        let user1Reward = await vt.connect(user1).balanceOf(user1.address, 1);
        console.log("User1 get reward:", user1Reward);
        let user2PreRewardState = await tscs.connect(owner).getUserLockReward(
            user2.address,
            LENS_ADDRESS,
            now
        );
        console.log("User2 pre reward state:", user2PreRewardState);
        let user3PreRewardState = await tscs.connect(owner).getUserLockReward(
            user3.address,
            LENS_ADDRESS,
            now
        );
        console.log("User3 pre reward state:", user3PreRewardState);
        let user4PreRewardState = await tscs.connect(owner).getUserLockReward(
            user4.address,
            LENS_ADDRESS,
            now
        );
        console.log("User4 pre reward state:", user4PreRewardState);
    });

    it("Test extract reward:", async function () {
        let tx;
        tx = await tscs.connect(user2).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user2BalanceNow = await vt.connect(user2).balanceOf(user2.address, 1);
        console.log("User2 get reward:", user2BalanceNow);
        tx = await tscs.connect(user3).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user3BalanceNow = await vt.connect(user3).balanceOf(user3.address, 1);
        console.log("User3 get reward:", user3BalanceNow);
        tx = await tscs.connect(user4).withdraw(LENS_ADDRESS, [now]);
        await tx.wait();
        let user4BalanceNow = await vt.connect(user4).balanceOf(user4.address, 1);
        console.log("User4 get reward:", user4BalanceNow);
    });

    it("Swap VT to Zimu", async function () {
        const approve = await vt.connect(user1).setApprovalForAll(authority.address, true);
        await approve.wait();
        const beforeBalance = await zimu.connect(owner).balanceOf(user1.address);
        console.log("beforeBalance: ", beforeBalance);
        const swap = await authority.connect(user1).swapInLens("100000");
        await swap.wait();
        const afterBalance = await zimu.connect(owner).balanceOf(user1.address);
        console.log("afterBalance: ", afterBalance);
    })
});

