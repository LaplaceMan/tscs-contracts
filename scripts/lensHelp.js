const { ethers } = require("ethers");
const coder = new ethers.utils.AbiCoder;

const collectPrice = ethers.utils.parseUnits("1", "ether");
const currency = "0x4996D5fd0A9C247c85eBC56f1A2A64c1A6980eAd";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
const collectModule = "0xa9917c3Aa1aCca02f5DfF305107883F564a47db6";

const createPostData = (price, token, owner) => {
    const setData = coder.encode(["uint256", "address", "address", "uint16", "bool"], [price, token, owner, "0", false]);
    console.log(setData);
}

const createCollectData = (token, price) => {
    const setData = coder.encode(["address", "uint256"], [token, price]);
    console.log(setData);
}

// createPostData(collectPrice, currency, "0x3f204Fcde7E2434FbC2BCdfF370e10065e499374");
createCollectData(currency, collectPrice);


// struct PostData {
//     uint256 profileId;
//     string contentURI;
//     address collectModule;
//     bytes collectModuleInitData;
//     address referenceModule;
//     bytes referenceModuleInitData;
// }

// [416, "https://arweave.net/S07X1ToOk0TuU8JAcLtIJJUO_5ea0Dgh43oVrV7Zv2w", "0xa9917c3Aa1aCca02f5DfF305107883F564a47db6", "0x0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000004996d5fd0a9c247c85ebc56f1a2a64c1a6980ead0000000000000000000000003f204fcde7e2434fbc2bcdff370e10065e49937400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x"]