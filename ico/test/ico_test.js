const { expect } = require("chai");
const { artifacts, web3 } = require("hardhat");
const ICO = artifacts.require("ICO");
const ICOJson = require("../artifacts/contracts/ICO.sol/ICO.json");
const TokenJson = require("../artifacts/contracts/Token.sol/MyToken.json");
describe("ICO Test", async() => {
    let ico, icoContract, token, owner, accounts;
    beforeEach(async() => {
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
        icoContract = await ICO.new(owner, 0, 100, 150);
        ico = await new web3.eth.Contract(ICOJson.abi, icoContract.address);
        tokenAddress = await ico.methods.myToken().call();
        token = await new web3.eth.Contract(TokenJson.abi, tokenAddress);
    });
    it("Invest fail", async() => {
        return ico.methods
            .invest()
            .send({ from: owner, value: web3.utils.toWei("1000") })
            .catch((err) => {
                assert.include(err.message, "Exceed maximum value of investment");
            });
    });
    it("Invest", async() => {
        await ico.methods
            .invest()
            .send({ from: owner, value: web3.utils.toWei("1") });
        let ownerBalance = await token.methods.balanceOf(owner).call();
        expect(ownerBalance).to.be.equal(web3.utils.toWei("1000"));
    });
    it("Try transfer when token is not tradeable", async() => {
        return token.methods
            .transfer(accounts[2], web3.utils.toWei("300"))
            .send({ from: owner })
            .catch((err) => assert.include(err.message, "token not tradeable yet"));
    });
});