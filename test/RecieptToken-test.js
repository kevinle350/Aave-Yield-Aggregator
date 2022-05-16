const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RecieptToken", function () {
    let RecieptToken;
    let recieptTokenContract;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        RecieptToken = await ethers.getContractFactory("contracts/RecieptToken.sol:RecieptToken");
        recieptTokenContract = await RecieptToken.deploy()
        await recieptTokenContract.deployed();

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    })

    describe("Deployment", function () {
        it("Should deploy with 10000 kUSDC", async function () {
            const ownerBalance = await recieptTokenContract.userBalance(owner.address)
            expect(ownerBalance).to.equal(10000);
        });
    })

    
    describe("Transactions", function () {
        it("Should mint 5 kUSDC to addr1", async function () {
            const addr1Init = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Init).to.equal(0)
            await recieptTokenContract.mintkUSDC(addr1.address, 5)
            const addr1Mint = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Mint).to.equal(5)
        });

        it("Should burn 5 kUSDC from addr1", async function () {
            const addr1Init = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Init).to.equal(0)
            await recieptTokenContract.mintkUSDC(addr1.address, 10)
            const addr1Mint = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Mint).to.equal(10)
            await recieptTokenContract.burnkUSDC(addr1.address, 5)
            const addr1Burn = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Burn).to.equal(5)
        });

        it("Should transfer 10 kUSDC from addr1 to addr2", async function () {
            const addr1Init = await recieptTokenContract.userBalance(addr1.address)
            const addr2Init = await recieptTokenContract.userBalance(addr2.address)
            expect(addr1Init).to.equal(0)
            expect(addr2Init).to.equal(0)

            await recieptTokenContract.mintkUSDC(addr1.address, 10)
            const addr1Mint = await recieptTokenContract.userBalance(addr1.address)
            expect(addr1Mint).to.equal(10)

            const addr2Allow1 = await recieptTokenContract.allowance(addr1.address, addr2.address)
            expect(addr2Allow1).to.equal(0)
            await recieptTokenContract.connect(addr1).approve(addr2.address, 10)
            const afterApprove = await recieptTokenContract.allowance(addr1.address, addr2.address)
            expect(afterApprove).to.equal(10)

            await recieptTokenContract.connect(addr1).transferkUSDC(addr2.address, 10)
            const addr1Transfer = await recieptTokenContract.userBalance(addr1.address)
            const addr2Transfer = await recieptTokenContract.userBalance(addr2.address)
            expect(addr1Transfer).to.equal(0)
            expect(addr2Transfer).to.equal(10)
        })
     })

});
