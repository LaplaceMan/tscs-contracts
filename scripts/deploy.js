const { ethers } = require("hardhat");
const main = async () => {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = deployer.address;
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
  const ARBITRATION = await ethers.getContractFactory("Arbitration");
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
  const erc20 = await ERC20.deploy();
  // 部署合约
  const murmes = await MURMES.deploy(deployerAddress, deployerAddress);
  const murmesEx = await MURMES.attach(murmes.address);
  console.log("Murmes Contract:", murmes.address);
  // 组件
  const ptoken = await PT.deploy(murmes.address);
  console.log("Platform Token Contract:", ptoken.address);
  const itoken = await IT.deploy(murmes.address);
  console.log("Item Token Contract:", itoken.address);
  const vault = await VAULT.deploy(murmes.address, deployerAddress);
  console.log("Vault Contract:", vault.address);
  const platforms = await PLATFORMS.deploy(murmes.address);
  console.log("Platforms Contract:", platforms.address);
  const platformsEx = await PLATFORMS.attach(platforms.address);
  const component = await COMPONENT.deploy(murmes.address, erc20.address);
  const componentEx = await COMPONENT.attach(component.address);
  console.log("Component Global Contract:", component.address);
  const moduleg = await MODULE.deploy(murmes.address);
  const modulegEx = await MODULE.attach(moduleg.address);
  console.log("Module Global Contract:", moduleg.address);
  const settlement = await SETTLEMENT.deploy(murmes.address);
  console.log("Settlement Contract:", settlement.address);
  const svm = await SVM.deploy(murmes.address);
  console.log("Version Management Contract:", svm.address);
  const arbitration = await ARBITRATION.deploy(murmes.address);
  console.log("Arbitration Contract:", arbitration.address);
  // 模块
  const authority = await AUTHORITY.deploy(murmes.address);
  console.log("Authority Contract:", authority.address);
  const access = await ACCESS.deploy(murmes.address);
  console.log("Access Contract:", access.address);
  const audit = await AUDIT.deploy(murmes.address, 1);
  console.log("Audit Contract:", audit.address);
  const detection = await DETECTION.deploy(murmes.address, 5);
  console.log("Detection Contract:", detection.address);
  const onetime0 = await ONETIME0.deploy(murmes.address);
  console.log("Settlement OT0 Contract:", onetime0.address);
  const divide1 = await DIVIDE1.deploy(murmes.address);
  console.log("Settlement D1 Contract:", divide1.address);
  const onetime2 = await ONETIME2.deploy(murmes.address);
  console.log("Settlement OT2 Contract:", onetime2.address);

  let tx;
  // 全局
  tx = await murmesEx.setGlobalContract(0, moduleg.address);
  tx = await murmesEx.setGlobalContract(1, component.address);
  // 组件
  tx = await componentEx.setComponent(0, vault.address);
  tx = await componentEx.setComponent(1, access.address);
  tx = await componentEx.setComponent(2, svm.address);
  tx = await componentEx.setComponent(3, platforms.address);
  tx = await componentEx.setComponent(4, settlement.address);
  tx = await componentEx.setComponent(5, authority.address);
  tx = await componentEx.setComponent(6, arbitration.address);
  tx = await componentEx.setComponent(7, itoken.address);
  tx = await componentEx.setComponent(8, ptoken.address);
  // 模块
  tx = await modulegEx.setSettlementModule(0, onetime0.address);
  tx = await modulegEx.setSettlementModule(1, divide1.address);
  tx = await modulegEx.setSettlementModule(2, onetime2.address);
  tx = await modulegEx.setWhitelistedCurrency(erc20.address, "true");
  tx = await modulegEx.setWhitelistedAuditModule(audit.address, "true");
  tx = await modulegEx.setDetectionModuleIsWhitelisted(detection.address, "true");

  const AUTHORITY0 = await ethers.getContractFactory("MurmesAuthority");
  const authority0 = await AUTHORITY0.deploy();
  tx = await platformsEx.setMurmesAuthorityModule(authority0.address);
  console.log("Murmes Authority Contract:", authority0.address);

  const AUTHORITY1 = await ethers.getContractFactory("DefaultAuthority");
  const authority1 = await AUTHORITY1.deploy(murmes.address);
  tx = await modulegEx.setAuthorityModuleIsWhitelisted(authority1.address, "true");
  console.log("Default Authority Contract:", authority1.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
