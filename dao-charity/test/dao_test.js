const { expect } = require("chai");
const { artifacts, web3 } = require("hardhat");
const DAO = artifacts.require("DAO");
const DAOJson = require("../artifacts/contracts/DAO.sol/DAO.json");

describe("DAO Test", async() => {
    let dao, daoContract, owner, accounts;
    beforeEach(async() => {
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
        daoContract = await DAO.new();
        dao = await new web3.eth.Contract(DAOJson.abi, daoContract.address);
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: accounts[1] });
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: accounts[2] });
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: accounts[3] });
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: accounts[4] });
    });
    it("Become contributor", async() => {
        await dao.methods
            .makeStakeholder(web3.utils.toWei("0.5"))
            .send({ from: owner });
        let isContributor = await dao.methods.isContributor().call();
        let isStakeholder = await dao.methods.isStakeholder().call();
        let ownerContributorBalance = await dao.methods
            .getContributorBalance(owner)
            .call();
        expect(isStakeholder).to.be.equal(false);
        expect(isContributor).to.be.equal(true);
        expect(ownerContributorBalance).to.be.equal(web3.utils.toWei("0.5"));
    });
    it("Become stakeholder", async() => {
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: owner });
        let isContributor = await dao.methods.isContributor().call();
        let isStakeholder = await dao.methods.isStakeholder().call();
        let ownerContributorBalance = await dao.methods
            .getContributorBalance(owner)
            .call();
        let ownerStakeholderBalance = await dao.methods
            .getStakeholderBalance(owner)
            .call();
        expect(isStakeholder).to.be.equal(true);
        expect(isContributor).to.be.equal(true);
        expect(ownerContributorBalance).to.be.equal(web3.utils.toWei("1"));
        expect(ownerStakeholderBalance).to.be.equal(web3.utils.toWei("1"));
    });
    it("Create proposal", async() => {
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: owner });
        await dao.methods
            .createProposal(web3.utils.toWei("0.3"), accounts[1], "for test")
            .send({ from: owner });
        let proposal = await dao.methods.getProposal(0).call();
        expect(proposal.description).to.be.equal("for test");
        expect(proposal.proposer).to.be.equal(owner);
    });
    it("Vote proposal", async() => {
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: owner });
        await dao.methods
            .createProposal(web3.utils.toWei("0.3"), accounts[1], "for test")
            .send({ from: owner });
        await dao.methods.vote(0, true).send({ from: owner });
        await dao.methods.vote(0, true).send({ from: accounts[1] });
        await dao.methods.vote(0, true).send({ from: accounts[2] });
        await dao.methods.vote(0, false).send({ from: accounts[3] });
        let proposal = await dao.methods.getProposal(0).call();
        expect(proposal.votesFor).to.be.equal("3");
        expect(proposal.votesAgainst).to.be.equal("1");
    });
    it("Pay charity fail", async() => {
        await dao.methods
            .makeStakeholder(web3.utils.toWei("1"))
            .send({ from: owner });
        await dao.methods
            .createProposal(web3.utils.toWei("0.3"), accounts[1], "for test")
            .send({ from: owner });
        return dao.methods
            .payCharity(0)
            .send({ from: owner })
            .catch((err) =>
                assert.include(err.message, "Proposal still in the voting period")
            );
    });
});