const { ethers } = require("hardhat");

const ModalGlobal_ADDRESS = "0xcbCC5b9611d22d11403373432642Df9Ef7Dd81AD";
const MockProfileCreationProxy_ADDRESS = "0x4fe8deB1cf6068060dE50aA584C3adf00fbDB87f"
const LENS_ADDRESS = "0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5";
const LENS_GOVERANCE_ADDRESS = "0x1677d9cC4861f1C85ac7009d5F06f49c928CA2AD";
const MURMES_ADDRESS = "0x2E2F1434Ce4D4Ec45bE6C3Cf4c6C70767D46259f";

const main = async () => {
    const lensModuleForMurmes = await ethers.getContractFactory("LensFeeModuleForMurmes");
    const module = await lensModuleForMurmes.deploy(LENS_ADDRESS, ModalGlobal_ADDRESS, MURMES_ADDRESS);
    const moduleAddress = module.address;
    console.log("Lens Module Contract", moduleAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });