//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
}

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user) external view
    returns (uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );
}

interface RecieptToken {
    function mintkUSDC(address _minter, uint _amount) external; 
    function burnkUSDC(address _minter, uint _amount) external;
}


contract YieldFarm {
    // Addresses
    address private PoolAddress = address(0x73A92E2b1Ec50bdf58aD5A2F6FAFB07d7D00E034);
    address private AaveProtocolDataProviderAddress = address(0x8e0988b28f9CdDe0134A206dfF94111578498C63);
    address private USDC = address(0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f);
    address private kUSDC = address(0x121332);    //fill this in later when contract deployed

    // Constant variables
    uint16 private refferalCode = 0;
    uint256 private interestRateMode = 1;   //stable: 1, variable:2

    address user;
    mapping(address => uint256) public userkUSDC;   // keeps track of how much initial kUSDC minted per user; the sum the map is the total supply of kUSDC

    constructor() {
        user = msg.sender;
    }

    // User deposits USDC into to this contract address -> USDC turns to aUSDC to be stored on this conract -> This contract does the work

    /* UI functions */

    // User deposits USDC into to this contract address
    function stakeUSDC(uint256 _amount) public {
        require(_amount > 0, "Amount should be greater than zero");
        IERC20(USDC).approve(address(this), _amount);
        IERC20(USDC).transferFrom(user, address(this), _amount);
        if (IERC20(kUSDC).balanceOf(address(this)) == 0) {
            userkUSDC[user] = _amount;
        } else {
            uint256 currentATokenBalance;
            (currentATokenBalance,,,,,,,,) = AaveProtocolDataProvider(AaveProtocolDataProviderAddress).getUserReserveData(USDC, address(this));
            uint256 ratio = currentATokenBalance/(IERC20(kUSDC).balanceOf(address(this)));
            uint256 kUSDCToMint = _amount * (1/ratio);
            RecieptToken(kUSDC).mintkUSDC(address(this), kUSDCToMint);
            userkUSDC[user] = kUSDCToMint;
        }
    }

    // User Withdraws their USDC + rewards
    // @TODO idt balance to withdraw is caculated like that, think about it again
    function withdrawUSDC() public {
        uint256 balance = (IERC20(kUSDC).balanceOf(address(this)))/userkUSDC[user];
        Pool(PoolAddress).withdraw(USDC, balance, address(this));
        RecieptToken(kUSDC).burnkUSDC(address(this), userkUSDC[user]);
        userkUSDC[user] = 0;
        IERC20(USDC).approve(user, balance);
        IERC20(USDC).transferFrom(address(this), user, balance);
    }


    /* These functions to be used for compounding */

    // USDC turns to aUSDC to be stored on this contract
    function supplyToAave(uint256 _amount) private {
        IERC20(USDC).approve(address(PoolAddress), _amount);
        Pool(PoolAddress).supply(USDC, _amount, address(this), refferalCode);
    }

    // Borrow USDC using the underlying aUSDC(from user to contract)
    function borrowFromAave(uint256 _amount) private {
        Pool(PoolAddress).borrow(USDC, _amount, interestRateMode, refferalCode, address(this));
    }

    // Repay debt to Aave from borrowing call
    function repayDebtAave() private {
        uint256 max = 2**256 - 1;   //supposed to use uint(-1) not sure why that errors
        IERC20(USDC).approve(address(PoolAddress), max);
        Pool(PoolAddress).repay(USDC, max, interestRateMode, address(this));
    }

    // Loops supplying and borrowing to Aave when supply APY > borrow APY
    // @TODO: Figure out how to get the Yields to loop
    function compound() private {
        
    }

    
}
