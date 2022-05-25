#   Aave Farm
Users deposit USDC into the UI. YieldFarm contract takes the USDC automatedly supplies the USDC into Aave as collateral and 
borrows more USDC. This action is looped for while the user hasn't withdrawn their USDC + rewards(from staking) and the acion is
executed when the supply APY is greater than the borrow APY to "compound" the yield; otherwise, USDC just left as collateral and gains
small yield from Aave. User withdraws and gets free yield just for depositing into our UI. We take 30% of the amccumulated yield for 
compounding the users yield for them. 

#   Approach
*   User deposit USDC which goes into YieldFarm contract
*   YieldFarm contract uses supply function from Aave Pool contract gets aUSDC
*   Uses supplied USDC to borrow more USDC if supply rate is higher than borrow rate
*   Get USDC yield on-chain or through theGraph protocl
*   Loop until user withdraws which returns their initial staked USDC + rewards from staking
*   Also make sure health ratio >= 1 to prevent liquidation
*   Take a cut (x%) of users profit, for now 30%
*   In testing, need to fork a chain otherwise its a clean chain and doesn't take an address

#    Think about
*    How to get max value to repay debt
*    Accounting for gas cost
*    Testing: how to get wallet with USDC 
*    Need to account for if there is enough liquidity to borrow

#    Resources
https://stackoverflow.com/questions/71106843/check-balance-of-erc20-token-in-hardhat-using-ethers-js

#   Notes
User supplies USDC
who gets aUSDC, the user or the contract 
If user gets aUSDC
aUSDC gives USDC + rewards
use user address to withdraw USDC using aUSDC as collateral which takes a fee but since we only do this if supply yield > we make profit


Bob
     -> 5 USDC -> 5 aUSDC = 5 kUSDC 
        6 aUSDC   

Alice
     -> 5 aUSDC * (5/6) = 4.16 kUSDC
        8 aUSDC
Joe
     -> 5 aUSDC * (9.16/14) = 3.27 kUSDC

kUSDC = 12.43
aUSDC = 19

Total kUSDC = 9.16
Withdraw(Bob): 9.16/5 = 1.832
Withdraw(Alice): 9.16/4.16 = 2.2019230769230769230769230769231

      underlying per receipt = (total aUSDC holdings)/(total supply of kUSDC)
      Anytime someone adds more aUSDC, they get deposited amount * ratio minted kUSDC
        ^ this value doesnt change but the total Aave amount will 
        Withdraw Total supply of kUSDC/(initial kUSDC minted)

6 + 5 = 11 aUSDC
11 * 
Bob: 11 * 5/9.16 = 6
Alice: 11 * 4.16/9.16 = 5

Bob: 19 * 5/12.43 = 7.64
Alice: 19 * 4.16/12.43 = 6.35
Joe: 19 * 3.27/12.43 = 4.99

(tot aUSDC) * (init kUSDC)/(tot kUSDC)