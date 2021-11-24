const { expect } = require("chai");
const { artifacts, web3 } = require("hardhat");
const Faucet = artifacts.require("Faucet");
const FaucetJson = require("../artifacts/contracts/Faucet.sol/Faucet.json");

describe("Faucet", async() => {
    let owner, accounts, faucet, faucetContract;
    beforeEach(async() => {
        faucetContract = await Faucet.new();
        faucet = await new web3.eth.Contract(
            FaucetJson.abi,
            faucetContract.address
        );
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
        await web3.eth.sendTransaction({
            from: owner,
            to: faucetContract.address,
            value: web3.utils.toWei("1"),
        });
    });
    it("Test Owner", async() => {
        console.log(owner);
    });
    it("Deposit", async() => {
        const balance = await web3.eth.getBalance(faucetContract.address);
        expect(balance).to.be.equal(web3.utils.toWei("1"));
    });
    it("Withdraw more than 0.1 ether", async() => {
        return faucet.methods
            .withdraw(web3.utils.toWei("0.2"))
            .send({ from: owner })
            .catch((err) => {
                assert.include(
                    err.message,
                    "only allowed withdraw more than 0.1 ether"
                );
            });
    });
    it("Withdraw normally", async() => {
        await faucet.methods
            .withdraw(web3.utils.toWei("0.1"))
            .send({ from: owner });
        const balance = await web3.eth.getBalance(faucetContract.address);
        expect(balance).to.be.equal(web3.utils.toWei("0.9"));
    });
});