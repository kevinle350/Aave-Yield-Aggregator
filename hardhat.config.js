require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("ethereum-waffle");
require("chai");
require("ethers");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});


// const AVALANCHE_TEST_PRIVATE_KEY = "";

module.exports = {
    solidity: "0.8.4",
    networks: {
        hardhat: {
            gas: 8 * 10 ** 6,  // tx gas limit
            blockGasLimit: 8 * 10 ** 6, // Avalanche Gas Limit
            gasPrice: 50537197095,
            allowUnlimitedContractSize: true,
            chainId: 1,
            // Uncomment when running normal tests, and comment when forking. set enabled to true
            //accounts: accountsList,
            forking: {
                enabled: true,
                // url: 'https://api.avax.network/ext/bc/C/rpc', // Mainnet
                // blockNumber: 7217503
                url: 'https://api.avax-test.network/ext/bc/C/rpc', // Testnet
                // blockNumber: 2672331
            }
        },
    }
    // networks: {
    //     avalancheTest: {
    //         url: 'https://api.avax-test.network/ext/bc/C/rpc',
    //         gasPrice: 225000000000,
    //         chainId: 43113,
    //         accounts: [`0x${AVALANCHE_TEST_PRIVATE_KEY}`]
    //     }
    // }
};
