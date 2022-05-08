#   Aave Farm

Users deposit USDC and get free Yield(rate tbd)

#   Approach

*   User deposit USDC which goes into YieldFarm contract
*   YieldFarm contract uses supply function from Aave Pool contract gets aUSDC
*   Uses supplied USDC to borrow more USDC if supply rate is higher than borrow rate
*   Loop until user withdraws which returns their initial staked USDC + rewards from staking
npm run build
npm run test
npm run local-testnet       //change this script to current contract
npm run deploy:local


https://www.youtube.com/watch?v=uhMOcD2oDFk
https://medium.com/coinmonks/create-and-deploy-a-solidity-contract-to-avalanche-with-hardhat-2c5cd5e4fa93
https://medium.com/coinmonks/create-an-avalanche-dapp-with-ethers-metamask-and-react-342d8d22cb30
