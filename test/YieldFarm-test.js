const { expect } = require("chai");
const { ethers } = require("hardhat");
const ERC20ABI = require('./ERC20.json');


describe("YieldFarm", function () {
    let RecieptToken;
    let recieptTokenContract;
    let YieldFarm;
    let yieldFarmContract;
    let owner;
    let addr1;
    let addr2;
    let addrs;
    const USDC_ADDRESS = "0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f";
    
    beforeEach(async function () {
        RecieptToken = await ethers.getContractFactory("contracts/RecieptToken.sol:RecieptToken");
        recieptTokenContract = await RecieptToken.deploy();
        await recieptTokenContract.deployed();
        let kUSDCAddr = recieptTokenContract.address;

        YieldFarm = await ethers.getContractFactory("YieldFarm");
        yieldFarmContract = await YieldFarm.deploy(kUSDCAddr);   
        await yieldFarmContract.deployed();

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    })

    describe("Supply to Aave", function () {
        it("Should supply 5 USDC to Aave", async function() {
            const USDC = new ethers.Contract(USDC_ADDRESS, ERC20ABI, owner);
            USDCBalance1 = await USDC.balanceOf(owner.address);
            expect(USDCBalance1).to.equal(0);
            await USDC.mint(owner.address, 10);
            USDCBalance2 = await USDC.balanceOf(owner.address);
            expect(USDCBalance2).to.equal(10);
            // Deposit 5 USDC to YieldFarm contracts
            await USDC.approve(yieldFarmContract.address, 5);
            spendLimit = await USDC.allowance(owner.address, yieldFarmContract.address);
            expect(spendLimit).to.equal(5);
            contractBal = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal).to.equal(0);
            ownerBal = await USDC.balanceOf(owner.address);
            expect(ownerBal).to.equal(10);
            await USDC.transfer(yieldFarmContract.address, 5);
            // After transfer
            ownerBal2 = await USDC.balanceOf(owner.address);
            expect(ownerBal2).to.equal(5);
            contractBal2 = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal2).to.equal(5);
            // Supply 5 USDC to Aave
            await yieldFarmContract._supplyToAave(USDC_ADDRESS, 5);
            contractBal3 = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal3).to.equal(0);
        })

        it("Should fail since Yield Contract doesn't have enough balance", async function() {
            const USDC = new ethers.Contract(USDC_ADDRESS, ERC20ABI, owner);
            USDCBalance1 = await USDC.balanceOf(owner.address);
            expect(USDCBalance1).to.equal(0);
            await USDC.mint(owner.address, 10);
            USDCBalance2 = await USDC.balanceOf(owner.address);
            expect(USDCBalance2).to.equal(10);
            // Deposit 5 USDC to YieldFarm contracts
            await USDC.approve(yieldFarmContract.address, 5);
            spendLimit = await USDC.allowance(owner.address, yieldFarmContract.address);
            expect(spendLimit).to.equal(5);
            contractBal = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal).to.equal(0);
            ownerBal = await USDC.balanceOf(owner.address);
            expect(ownerBal).to.equal(10);
            await USDC.transfer(yieldFarmContract.address, 5);
            // After transfer
            ownerBal2 = await USDC.balanceOf(owner.address);
            expect(ownerBal2).to.equal(5);
            contractBal2 = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal2).to.equal(5);
            // Supply 5 USDC to Aave
            await expect(yieldFarmContract._supplyToAave(USDC_ADDRESS, 6)).to.be.revertedWith('Insufficient balance');
        })
    })

    describe("Stake to contract", function() {
        it("Should give user reciept token of 5 kUSDC ~ Single user", async function() {
            const USDC = new ethers.Contract(USDC_ADDRESS, ERC20ABI, owner);
            ownerBal1 = await USDC.balanceOf(owner.address);
            expect(ownerBal1).to.equal(0);
            await USDC.mint(owner.address, 100);
            ownerBal2 = await USDC.balanceOf(owner.address);
            expect(ownerBal2).to.equal(100);

            kUSDCBal = await yieldFarmContract.getInitialToken(owner.address);
            expect(kUSDCBal).to.equal(0)

            contractBal1 = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal1).to.equal(0);
            console.log('%cYieldFarm-test.js line:98 ownerBal2', 'color: #007acc;', ownerBal2);
            await USDC.approve(yieldFarmContract.address, 5);   // Have to do approve call outside of function for some reason
            await yieldFarmContract.testStake(5);   
            kUSDCBal2 = await yieldFarmContract.getInitialToken(owner.address);
            expect(kUSDCBal2).to.equal(5);
        })

        it.only("Should give owner reciept token of 5 kUSDC and addr1 5 kUSD ~ Multiple users", async function() {  // Figure out how to do this with time skip so aUSDC changes
            const USDC = new ethers.Contract(USDC_ADDRESS, ERC20ABI, owner);
            ownerBal1 = await USDC.balanceOf(owner.address);
            expect(ownerBal1).to.equal(0);
            await USDC.mint(owner.address, 100);
            ownerBal2 = await USDC.balanceOf(owner.address);
            expect(ownerBal2).to.equal(100);

            await USDC.approve(addr1.address, 50);
            await USDC.transfer(addr1.address, 50);
            addr1Bal1 = await USDC.balanceOf(addr1.address);
            expect(addr1Bal1).to.equal(50);

            kUSDCBal = await yieldFarmContract.getInitialToken(owner.address);
            expect(kUSDCBal).to.equal(0)
            addr1kUSDCBal = await yieldFarmContract.getInitialToken(addr1.address);
            expect(addr1kUSDCBal).to.equal(0)

            contractBal1 = await USDC.balanceOf(yieldFarmContract.address);
            expect(contractBal1).to.equal(0);
            console.log('%cYieldFarm-test.js line:98 ownerBal2', 'color: #007acc;', ownerBal2);
            await USDC.approve(yieldFarmContract.address, 5);   // Have to do approve call outside of function for some reason
            await yieldFarmContract.testStake(5);   
            kUSDCBal2 = await yieldFarmContract.getInitialToken(owner.address);
            expect(kUSDCBal2).to.equal(5);

            await USDC.connect(addr1).approve(yieldFarmContract.address, 5);
            await yieldFarmContract.connect(addr1).testStake(5);

            kUSDCBal2 = await yieldFarmContract.getInitialToken(owner.address);
            expect(kUSDCBal2).to.equal(5);
            addr1kUSDCBal2 = await yieldFarmContract.getInitialToken(addr1.address);
            expect(addr1kUSDCBal2).to.equal(5);
        })
        
    })

    describe("Withdraw from contract", async function() {

    })

    // describe("APY", function () {
    //     it("Should get supply and borrow APYs", async function () {
    //         let bothAPY = await yieldFarmContract.getAPYs();
    //         let supplyAPY = bothAPY.depositAPY;
    //         let borrowAPY = bothAPY.stableBorrowAPY;
    //         // supplyAPY = await yieldFarmContract.getAPYs();
    //         console.log('%cYieldFarm-test.js line:33 bothAPY', 'color: #007acc;', bothAPY);
    //         console.log('%cYieldFarm-test.js line:25 supplyAPY', 'color: #007acc;', supplyAPY);
    //         console.log('%cYieldFarm-test.js line:26 borrowAPY', 'color: #007acc;', borrowAPY);
    //     });
    // })

});
