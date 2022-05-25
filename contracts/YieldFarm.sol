//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import './DataTypes.sol';

interface Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
    function getReserveData(address asset) external returns (DataTypes.ReserveData memory);
    function getUserAccountData(address user) external view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}

interface RecieptToken {
    function mintkUSDC(address _minter, uint _amount) external;
    function burnkUSDC(address _minter, uint _amount) external;
    function transferkUSDC(address _to, uint _amount) external;
    function userBalance(address account) external view returns (uint256);
}

contract YieldFarm {
    // Addresses
    address private PoolAddress;
    address private USDC;
    address private kUSDC;
    address private aUSDC; 

    // Constant variables
    uint16 private constant refferalCode = 0;
    uint256 private constant interestRateMode = 1;   //stable: 1, variable:2

    address private owner;
    mapping(address => uint256) private userkUSDC;   // keeps track of how much initial kUSDC minted per user; the sum the map is the total supply of kUSDC
    uint256 tracker;    // 0 == no stakers, else theres a staker

    constructor(address _kUSDC) {
        PoolAddress = address(0xb47673b7a73D78743AFF1487AF69dBB5763F00cA);  // pool proxy
        USDC = address(0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f);
        kUSDC = _kUSDC;
        DataTypes.ReserveData memory reserves = Pool(PoolAddress).getReserveData(USDC);
        aUSDC = reserves.aTokenAddress;
        owner = msg.sender;
    }

    /* UI functions */

    // User deposits USDC into to this contract address
    // Stake = (init USDC) * (tot kUSDC)/(tot aUSDC)
    function stakeUSDC(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than zero");
        IERC20(USDC).approve(address(this), _amount);   // need to approve outside of the function
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
        if (tracker == 0) {
            userkUSDC[msg.sender] = _amount;
            RecieptToken(kUSDC).mintkUSDC(address(this), _amount);
        } else {
            uint256 currentATokenBalance = IERC20(aUSDC).balanceOf(address(this));
            uint256 currentkUSDCBalance = RecieptToken(kUSDC).userBalance(address(this));
            uint256 ratio = currentkUSDCBalance/currentATokenBalance;
            uint256 kUSDCToMint = _amount * ratio;
            RecieptToken(kUSDC).mintkUSDC(address(this), kUSDCToMint);
            userkUSDC[msg.sender] = kUSDCToMint;
        }
        IERC20(USDC).approve(address(PoolAddress), _amount);
        Pool(PoolAddress).supply(USDC, _amount, address(this), refferalCode);
        tracker += 1;
        _looping();
    }

    // User Withdraws their total USDC + rewards
    // balance = (tot aUSDC) * (init kUSDC)/(tot kUSDC)
    function withdrawUSDC() external {
        uint256 currentATokenBalance = IERC20(aUSDC).balanceOf(address(this));
        uint256 currentkUSDCBalance = RecieptToken(kUSDC).userBalance(address(this));
        uint256 ratio = userkUSDC[msg.sender]/currentkUSDCBalance;
        uint256 balance = currentATokenBalance * ratio;
        Pool(PoolAddress).withdraw(USDC, balance, address(this));
        RecieptToken(kUSDC).burnkUSDC(address(this), userkUSDC[msg.sender]);
        userkUSDC[msg.sender] = 0;
        uint256 cut = balance * 70/100;
        IERC20(USDC).approve(msg.sender, cut);
        IERC20(USDC).transferFrom(address(this), msg.sender, cut);
        tracker -= 1;   // Remove staker
    }


    /* These functions to be used for looping */

    // USDC turns to aUSDC to be stored on this contract
    function _supplyToAave(address _token, uint256 _amount) public {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient balance");
        IERC20(_token).approve(address(PoolAddress), _amount);     // _token should be aUSDC
        Pool(address(PoolAddress)).supply(_token, _amount, address(this), refferalCode);  
    }

    // Borrow USDC using the underlying aUSDC(from user to contract)
    function _borrowFromAave(address _token, uint256 _amount) public {
        Pool(PoolAddress).borrow(_token, _amount, interestRateMode, refferalCode, address(this));   // _token should be aUSDC
    }

    // Repay debt to Aave from borrowing call
    function _repayDebtAave(address _token) public {
        uint256 max = 2**256 - 1;   //supposed to use uint(-1) not sure why that errors
        IERC20(_token).approve(address(PoolAddress), max);  // _token should be aUSDC
        Pool(PoolAddress).repay(_token, max, interestRateMode, address(this));
    }

    function getAPYs() public returns(uint256, uint256) {
        uint256 RAY = 10**27;
        uint256 SECONDS_PER_YEAR = 31536000;
        uint128 liquidityRate = Pool(PoolAddress).getReserveData(USDC).currentLiquidityRate;
        uint128 currentStableBorrowRate = Pool(PoolAddress).getReserveData(USDC).currentStableBorrowRate;

        // Deposit and Borrow calculations
        // APY and APR are returned here as decimals, multiply by 100 to get the percents

        uint256 depositAPR = liquidityRate/RAY;
        uint256 stableBorrowAPR = currentStableBorrowRate/RAY;

        uint256 depositAPY = ((1 + (depositAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;
        uint256 stableBorrowAPY = ((1 + (stableBorrowAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;

        return(depositAPY, stableBorrowAPY);
    }


    // Loops supplying and borrowing to Aave when supply APY > borrow APY
    function _looping() private {
        uint256 depositAPY;
        uint256 borrowAPY;
        uint256 healthFactor;
        (,,,,,healthFactor) = Pool(PoolAddress).getUserAccountData(address(this));  // Do I have to put this in the loop or does it update by itself
        while (healthFactor >= 1) {    
            (depositAPY, borrowAPY) = getAPYs();
            if (borrowAPY < depositAPY) {
                uint256 amount = IERC20(aUSDC).balanceOf(address(this));
                _supplyToAave(aUSDC, amount);
                _borrowFromAave(aUSDC, amount);
                _repayDebtAave(aUSDC);
            }
        }
    }

    
    /* Functions for testing  */

    // Without looping
    function testStake(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than zero");
        // IERC20(USDC).approve(address(this), _amount);
        approveToken(_amount);  // need to approve outside of the function
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
        if (tracker == 0) {  // When there are no stakers
            userkUSDC[msg.sender] = _amount;    
            RecieptToken(kUSDC).mintkUSDC(address(this), _amount);
            console.log("Bob");
        } else {
            console.log("Alice");
            uint256 currentATokenBalance = IERC20(aUSDC).balanceOf(address(this));  // 5
            console.log(currentATokenBalance);
            uint256 currentkUSDCBalance = RecieptToken(kUSDC).userBalance(address(this));   // 0
            console.log(currentkUSDCBalance);
            uint256 ratio = currentkUSDCBalance/currentATokenBalance;   // Fails here prob some decimal error
            console.log("Here");
            uint256 kUSDCToMint = _amount * ratio;
            RecieptToken(kUSDC).mintkUSDC(address(this), kUSDCToMint);
            userkUSDC[msg.sender] = kUSDCToMint;
        }      
        IERC20(USDC).approve(address(PoolAddress), _amount);
        Pool(PoolAddress).supply(USDC, _amount, address(this), refferalCode);
        tracker += 1;
        console.log("Out");
    }

    function approveToken(uint256 _amount) public {
        IERC20(USDC).approve(address(this), _amount);
    }

    function getInitialToken(address _user) external view returns(uint256) {
        return userkUSDC[_user];
    }

    function transferToken(uint256 _amount) external {
        uint256 bal = IERC20(USDC).balanceOf(msg.sender);
        console.log(bal);

        // IERC20(USDC).approve(address(this), _amount+1);
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);

        // IERC20(USDC).transfer(address(this), _amount);
        console.log("After contract transfer");
        uint256 bal2 = IERC20(USDC).balanceOf(msg.sender);
   
        console.log(bal2);
    }

}


