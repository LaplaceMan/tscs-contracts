const { ethers } = require("hardhat");

const LENS_ADDRESS = "0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5";
const MURMES_ADDRESS = "0x87042950BFCE9b365E3C1E21C5DD343Cb8AcDA95";

const main = async () => {
    const AUTHORITY = await ethers.getContractFactory("AuthorityStrategy");
    const authority = await AUTHORITY.deploy(MURMES_ADDRESS, LENS_ADDRESS);
    const authorityAddress = await authority.address;
    console.log(authorityAddress)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });