#   Aave Farm

Users deposit USDC and get free Yield(rate tbd)

#   Approach

*   User deposit USDC which goes into YieldFarm contract
*   YieldFarm contract uses supply function from Aave Pool contract gets aUSDC
*   Uses supplied USDC to borrow more USDC if supply rate is higher than borrow rate
*   Use AaveOracle to get USDC yields
*   Loop until user withdraws which returns their initial staked USDC + rewards from staking
npm run build
npm run test
npm run local-testnet       //change this script to current contract
npm run deploy:local

#   Resources
https://www.youtube.com/watch?v=uhMOcD2oDFk
https://medium.com/coinmonks/create-and-deploy-a-solidity-contract-to-avalanche-with-hardhat-2c5cd5e4fa93
https://medium.com/coinmonks/create-an-avalanche-dapp-with-ethers-metamask-and-react-342d8d22cb30

#   Notes
User supplies USDC
who gets aUSDC, the user or the contract 
If user gets aUSDC
aUSDC gives USDC + rewards
use user address to withdraw USDC using aUSDC as collateral which takes a fee but since we only do this if supply yield > we make profit


Bob
Start -> 5 USDC -> 5 aUSDC = 5 kUSDC minted
After time         6 aUSDC   5 kUSDC

Alice
     -> 5 aUSDC * (5/6) = 4.16 kUSDC

Total kUSDC = 9.16
Withdraw(Bob): 9.16/5 = 1.832
Withdraw(Alice): 9.16/4.16 = 2.2019230769230769230769230769231

      underlying per receipt = (total aUSDC holdings)/(total supply of kUSDC)
      Anytime someone adds more aUSDC, they get deposited amount * ratio minted kUSDC
        ^ this value doesnt change but the total Aave amount will 
        Withdraw Total supply of kUSDC/(initial kUSDC minted)