const ICO = artifacts.require("ICO");
const myAddress = "0x549F8cC1Bca2e1EbBEA54b4dB3D36E54af5571d1";
module.exports = function (deployer) {
  deployer.deploy(ICO, myAddress, 29549472, 39549472, 40500000);
};
