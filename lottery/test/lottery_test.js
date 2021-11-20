const { expect } = require("chai");
const { artifacts, web3 } = require("hardhat");
const Lottery = artifacts.require("Lottery");
const LotteryJson = require("../artifacts/contracts/Lottery.sol/Lottery.json");
module.exports = async function() {
    let accounts, lotteryContract, lottery, owner;
    beforeEach(async() => {
        lotteryContract = await Lottery.new();
        lottery = await new web3.eth.Contract(
            LotteryJson.abi,
            lotteryContract.address
        );
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
    });
    it("participate", async() => {
        await lottery.methods
            .participate()
            .send({ value: web3.utils.toWei("0.1"), from: owner });
        await lottery.methods
            .participate()
            .send({ value: web3.utils.toWei("0.5"), from: accounts[1] });
        const contractBalance = await web3.eth.getBalance(lotteryContract.address);
        expect(contractBalance).to.equal(web3.utils.toWei("0.6"));
    });
    it("execute", async() => {
        await lottery.methods
            .participate()
            .send({ value: web3.utils.toWei("1000"), from: owner });
        await lottery.methods
            .participate()
            .send({ value: web3.utils.toWei("1000"), from: accounts[1] });
        await lottery.methods.execute().send({ from: owner });
        const acc1Balance = await web3.eth.getBalance(accounts[1]);
        const ownerBalance = await web3.eth.getBalance(owner);
        console.log(acc1Balance);
        console.log(ownerBalance);
    });
};