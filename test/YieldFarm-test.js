const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("YieldFarm", function () {
    let RecieptToken;
    let recieptTokenContract;
    let YieldFarm;
    let yieldFarmContract;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        RecieptToken = await ethers.getContractFactory("contracts/RecieptToken.sol:RecieptToken");
        recieptTokenContract = await RecieptToken.deploy();
        await recieptTokenContract.deployed();
        let kUSDCAddr = recieptTokenContract.address;

        YieldFarm = await ethers.getContractFactory("YieldFarm");
        yieldFarmContract = await YieldFarm.deploy(kUSDCAddr);   // fails here
        await yieldFarmContract.deployed();

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        let bal1 = await owner.getBalance();
        let bal2 = await addr1.getBalance();
        console.log(bal1)
        console.log(bal2)
    })

    describe("Supply", function () {
        it("Should supply 5 USDC to Aave", async function() {
            
        })
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
