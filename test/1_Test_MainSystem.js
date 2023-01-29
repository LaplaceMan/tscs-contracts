const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
let tscs, zimu, vt, st, platform, access, audit, detection, divide1, onetime0, onetime2;
let tscsAsDeployer, platformAsDeployer;
let owner, user1, user2, user3;
const baseEthAmount = ethers.utils.parseUnits("60", "ether");
const unitEthAmount = ethers.utils.parseUnits("20", "ether");

describe("MainSystem_Base_Test", function () {
    it("Deploy contracts", async function () {
        // 获得区块链网络提供的测试账号
        const [deployer, addr1, addr2, addr3] = await ethers.getSigners();
        deployerAddress = deployer.address;
        owner = deployer;
        user1 = addr1;
        user2 = addr2;
        user3 = addr3;

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
    });

    it("Test Zimu transfer", async function () {
        await zimu.deployed();
        const balanceUser1old = await zimu.connect(user1).balanceOf(user1.address);
        console.log("User1 Zimu balance before transfer is", balanceUser1old);
        let tx = await zimu.connect(owner).transfer(user1.address, baseEthAmount);
        await tx.wait();
        const balanceUser1new = await zimu.connect(user1).balanceOf(user1.address);
        console.log("User1 Zimu balance after transfer is", balanceUser1new);
        expect(balanceUser1new).to.equal(baseEthAmount);
    });

    it("Test user join", async function () {
        let tx = await zimu.connect(user1).approve(tscs.address, baseEthAmount);
        await tx.wait();
        const user1Approved = await zimu
            .connect(user1)
            .allowance(user1.address, tscs.address);
        console.log("User1-TSCS Zimu approved amount:", user1Approved);
        expect(user1Approved).to.equal(baseEthAmount);
        await expect(tscs.connect(user1).userJoin(user1.address, unitEthAmount))
            .to.emit(tscs, "UserJoin")
            .withArgs(user1.address, BigNumber.from("1000"), unitEthAmount);
        let user1JoinInfo = await tscs
            .connect(user1)
            .getUserBaseInfo(user1.address);
        console.log("User joined info:", user1JoinInfo);
    });

    it("Despoit for audit", async function () {
        let tx = await zimu.connect(owner).transfer(user2.address, baseEthAmount);
        await tx.wait();
        tx = await zimu.connect(owner).transfer(user3.address, baseEthAmount);
        await tx.wait();
        tx = await zimu
            .connect(user2)
            .approve(tscs.address, baseEthAmount);
        await tx.wait();
        tx = await zimu
            .connect(user3)
            .approve(tscs.address, baseEthAmount);
        await tx.wait();
        tx = await tscs.connect(user2).userJoin(user2.address, baseEthAmount);
        await tx.wait();
        tx = await tscs.connect(user3).userJoin(user3.address, baseEthAmount);
        await tx.wait();
    });

    // 测试时将 AuditStrategy 中的审核次数从 10 => 2, 且 AuditTime = 0
    it("Test add language", async function () {
        let tx = await tscsAsDeployer.registerLanguage(['cn', 'us', 'jp']);
        await tx.wait();
        let cnIndex = await tscsAsDeployer.getLanguageIdByNote('cn');
        let enIndex = await tscsAsDeployer.getLanguageIdByNote('us');
        let jpIndex = await tscsAsDeployer.getLanguageIdByNote('jp');
        expect(cnIndex).to.equal(1);
        expect(enIndex).to.equal(2);
        expect(jpIndex).to.equal(3);
    });

    it("Test submit application (OT0)", async function () {
        const date = "0x" + (parseInt(Date.now() / 1000) + 15778800).toString(16);
        let tx = await tscs
            .connect(user1)
            .submitApplication(tscs.address, 0, 0, unitEthAmount, 1, date, "test");
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Test upload subtitle", async function () {
        let tx = await tscs.connect(user3).uploadSubtitle(1, "testtest", 1, "1000");
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Test upload subtitles", async function () {
        let tx = await tscs.connect(user2).uploadSubtitle(1, "testtesttest", 1, "0x1a2b");
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });

    it("Test evaluate (audit) subtitle", async function () {
        let tx = await tscs.connect(user3).evaluateSubtitle(1, 0);
        await tx.wait();
        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        expect(receipt.status).to.equal(1);
    });
});

describe("MainSystem_Other_Test", function () {
    it("Test add platform", async function () {
        await expect(
            platformAsDeployer.platfromJoin(owner.address, "test", "test", 655, 655)
        )
            .to.emit(platform, "PlatformJoin")
            .withArgs(
                owner.address,
                BigNumber.from("1"),
                "test",
                "test",
                BigNumber.from("655"),
                BigNumber.from("655")
            );
    });

    it("Test platform add (create) video", async function () {
        await expect(platformAsDeployer.createVideo(1, "test", user1.address))
            .to.emit(platform, "VideoCreate")
            .withArgs(
                owner.address,
                BigNumber.from("1"),
                BigNumber.from("1"),
                "test",
                user1.address
            );
    });

    it("Test platform update counts", async function () {
        await expect(platformAsDeployer.updateViewCounts([1], [10000]))
            .to.emit(platform, "VideoCountsUpdate")
            .withArgs(
                owner.address, [BigNumber.from("1")], [BigNumber.from("10000")]
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
                BigNumber.from("1"),
                BigNumber.from("1"),
                BigNumber.from("655"),
                BigNumber.from("1"),
                BigNumber.from(date),
                BigNumber.from("2"),
                "test"
            );
    });
});