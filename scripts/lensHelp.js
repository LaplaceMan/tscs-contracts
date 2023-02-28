const { ethers } = require("ethers");
const coder = new ethers.utils.AbiCoder;

const collectPrice = ethers.utils.parseUnits("1", "ether");
const zimu = "0x8928C5568a7Bc0da7F0f2CF6027AC7F3f8bf68f3";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

const createPostData = (price, token, owner) => {
    const setData = coder.encode(["uint256", "address", "address", "uint16", "bool"], [price, token, owner, "0", false]);
    console.log(setData);
}

const createCollectData = (token, price) => {
    const setData = coder.encode(["address", "uint256"], [token, price]);
    console.log(setData);
}
// createPostData(collectPrice, zimu, "0x3f204Fcde7E2434FbC2BCdfF370e10065e499374");
createCollectData(zimu, collectPrice);


// [415, "https://arweave.net/S07X1ToOk0TuU8JAcLtIJJUO_5ea0Dgh43oVrV7Zv2w", "0x20d1933080d7B77EcF09EaA7F32b81E1a17c28a1", "0x0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000008928c5568a7bc0da7f0f2cf6027ac7f3f8bf68f30000000000000000000000007e489ecad625e8e29c0cf77434c89dbef2c3c2b400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x"]