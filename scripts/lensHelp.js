const { ethers } = require("ethers");
const coder = new ethers.utils.AbiCoder;

const collectPrice = ethers.utils.parseUnits("1", "ether");
const zimu = "0xAAA6490eE20Fb1407e67E59F0e1B45Dab912B3aE";


const createPostData = (price, token, owner) => {
    const setData = coder.encode(["uint256", "address", "address", "uint16", "bool"], [price, token, owner, "0", false]);
    console.log(setData);
}

createPostData(collectPrice, zimu, "0x7E489eCAD625e8e29C0cF77434c89DBef2c3c2b4");
// [415, "https://arweave.net/S07X1ToOk0TuU8JAcLtIJJUO_5ea0Dgh43oVrV7Zv2w", "0xf40b0a312A791A48e7550EC810Be0Ac82d708B3d", ]