const { ethers } = require("hardhat");

const LENS_ADDRESS = "0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5";
const MURMES_ADDRESS = "0x2E2F1434Ce4D4Ec45bE6C3Cf4c6C70767D46259f";

const main = async () => {
    const AUTHORITY = await ethers.getContractFactory("LensAuthority");
    const authority = await AUTHORITY.deploy(MURMES_ADDRESS, LENS_ADDRESS);
    const authorityAddress = await authority.address;
    console.log("Lens Authority Contract:", authorityAddress)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });