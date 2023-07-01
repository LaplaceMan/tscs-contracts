const { ethers } = require("hardhat");

function sleep(time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}

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
  console.log("ERC20 Mintable Contract:", erc20.address);
  // 部署合约
  const murmes = await MURMES.deploy(deployerAddress, deployerAddress);
  const murmesEx = await MURMES.attach(murmes.address);
  console.log("Murmes Contract:", murmes.address);
  // 组件
  const ptoken = await PT.deploy(murmes.address);
  console.log("Platform Token Contract:", ptoken.address);
  await sleep(3000);
  const itoken = await IT.deploy(murmes.address);
  console.log("Item Token Contract:", itoken.address);
  await sleep(3000);
  const vault = await VAULT.deploy(murmes.address, deployerAddress);
  console.log("Vault Contract:", vault.address);
  await sleep(3000);
  const AUTHORITY0 = await ethers.getContractFactory("MurmesAuthority");
  const authority0 = await AUTHORITY0.deploy();
  console.log("Murmes Authority Contract:", authority0.address);
  await sleep(3000);
  const platforms = await PLATFORMS.deploy(murmes.address, authority0.address);
  console.log("Platforms Contract:", platforms.address);
  await sleep(3000);
  const component = await COMPONENT.deploy(murmes.address, erc20.address);
  const componentEx = await COMPONENT.attach(component.address);
  console.log("Component Global Contract:", component.address);
  await sleep(3000);
  const moduleg = await MODULE.deploy(murmes.address);
  const modulegEx = await MODULE.attach(moduleg.address);
  console.log("Module Global Contract:", moduleg.address);
  await sleep(3000);
  const settlement = await SETTLEMENT.deploy(murmes.address);
  console.log("Settlement Contract:", settlement.address);
  await sleep(3000);
  const svm = await SVM.deploy(murmes.address);
  console.log("Version Management Contract:", svm.address);
  await sleep(3000);
  const arbitration = await ARBITRATION.deploy(murmes.address);
  console.log("Arbitration Contract:", arbitration.address);
  await sleep(3000);
  // 模块
  const authority = await AUTHORITY.deploy(murmes.address);
  console.log("Authority Contract:", authority.address);3
  await sleep(3000);
  const access = await ACCESS.deploy(murmes.address);
  console.log("Access Contract:", access.address);
  await sleep(3000);
  const audit = await AUDIT.deploy(murmes.address, 1, "DEFAULT_MAJORITY");
  console.log("Audit Contract:", audit.address);
  await sleep(3000);
  const detection = await DETECTION.deploy(murmes.address, 5, "DEFAULT_HAMMING");
  console.log("Detection Contract:", detection.address);
  await sleep(3000);
  const onetime0 = await ONETIME0.deploy(murmes.address);
  console.log("Settlement OT0 Contract:", onetime0.address);
  await sleep(3000);
  const divide1 = await DIVIDE1.deploy(murmes.address);
  console.log("Settlement D1 Contract:", divide1.address);
  await sleep(3000);
  const onetime2 = await ONETIME2.deploy(murmes.address);
  console.log("Settlement OT2 Contract:", onetime2.address);

  let tx;
  // 全局
  await sleep(3000);
  tx = await murmesEx.setGlobalContract(0, moduleg.address);
  await sleep(3000);
  tx = await murmesEx.setGlobalContract(1, component.address);
  await sleep(3000);
  // 组件
  tx = await componentEx.setComponent(0, vault.address);
  await sleep(3000);
  tx = await componentEx.setComponent(1, access.address);
  await sleep(3000);
  tx = await componentEx.setComponent(2, svm.address);
  await sleep(3000);
  tx = await componentEx.setComponent(3, platforms.address);
  await sleep(3000);
  tx = await componentEx.setComponent(4, settlement.address);
  await sleep(3000);
  tx = await componentEx.setComponent(5, authority.address);
  await sleep(3000);
  tx = await componentEx.setComponent(6, arbitration.address);
  await sleep(3000);
  tx = await componentEx.setComponent(7, itoken.address);
  await sleep(3000);
  tx = await componentEx.setComponent(8, ptoken.address);
  await sleep(3000);
  // 模块
  tx = await modulegEx.setSettlementModule(0, onetime0.address);
  await sleep(3000);
  tx = await modulegEx.setSettlementModule(1, divide1.address);
  await sleep(3000);
  tx = await modulegEx.setSettlementModule(2, onetime2.address);
  await sleep(3000);
  tx = await modulegEx.setWhitelistedCurrency(erc20.address, "true");
  await sleep(3000);
  tx = await modulegEx.setWhitelistedAuditModule(audit.address, "true");
  await sleep(3000);
  tx = await modulegEx.setDetectionModuleIsWhitelisted(detection.address, "true");
  await sleep(3000);

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
