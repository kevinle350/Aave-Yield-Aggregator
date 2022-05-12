//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import './DataTypes.sol';
import './RecieptToken.sol';

interface Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
    function getReserveData(address asset) external returns (DataTypes.ReserveData memory);
}


contract YieldFarm {
    // Addresses
    address private PoolAddress = address(0x73A92E2b1Ec50bdf58aD5A2F6FAFB07d7D00E034);
    address private USDC = address(0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f);
    address private kUSDC = address(0x121332);    //fill this in later when contract deployed
    address private aUSDC = Pool(PoolAddress).getReserveData(USDC).aTokenAddress;

    // Constant variables
    uint16 private constant refferalCode = 0;
    uint256 private constant interestRateMode = 1;   //stable: 1, variable:2

    address private owner;
    mapping(address => uint256) private userkUSDC;   // keeps track of how much initial kUSDC minted per user; the sum the map is the total supply of kUSDC

    constructor() {
        owner = msg.sender;
    }

    /* UI functions */

    // User deposits USDC into to this contract address
    // Stake = (init USDC) * (tot kUSDC)/(tot aUSDC)
    function stakeUSDC(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than zero");
        IERC20(USDC).approve(address(this), _amount);
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
        if (IERC20(kUSDC).balanceOf(address(this)) == 0) {
            userkUSDC[msg.sender] = _amount;
        } else {
            uint256 currentATokenBalance = IERC20(aUSDC).balanceOf(address(this));
            uint256 currentkUSDCBalance = IERC20(kUSDC).balanceOf(address(this));
            uint256 ratio = currentkUSDCBalance/currentATokenBalance;
            uint256 kUSDCToMint = _amount * ratio;
            RecieptToken(kUSDC).mintkUSDC(address(this), kUSDCToMint);
            userkUSDC[msg.sender] = kUSDCToMint;
        }
        IERC20(USDC).approve(address(PoolAddress), _amount);
        Pool(PoolAddress).supply(USDC, _amount, address(this), refferalCode);
        _looping();
    }

    // User Withdraws their USDC + rewards
    // balance = (tot aUSDC) * (init kUSDC)/(tot kUSDC)
    function withdrawUSDC() external {
        uint256 currentATokenBalance = IERC20(aUSDC).balanceOf(address(this));
        uint256 currentkUSDCBalance = IERC20(kUSDC).balanceOf(address(this));
        uint256 ratio = userkUSDC[msg.sender]/currentkUSDCBalance;
        uint256 balance = currentATokenBalance * ratio;
        Pool(PoolAddress).withdraw(USDC, balance, address(this));
        RecieptToken(kUSDC).burnkUSDC(address(this), userkUSDC[msg.sender]);
        userkUSDC[msg.sender] = 0;
        IERC20(USDC).approve(msg.sender, balance);
        IERC20(USDC).transferFrom(address(this), msg.sender, balance);
    }


    /* These functions to be used for looping */

    // USDC turns to aUSDC to be stored on this contract
    function _supplyToAave(uint256 _amount) private {
        IERC20(aUSDC).approve(address(PoolAddress), _amount);
        Pool(PoolAddress).supply(aUSDC, _amount, address(this), refferalCode);
    }

    // Borrow USDC using the underlying aUSDC(from user to contract)
    function _borrowFromAave(uint256 _amount) private {
        Pool(PoolAddress).borrow(aUSDC, _amount, interestRateMode, refferalCode, address(this));
    }

    // Repay debt to Aave from borrowing call
    function _repayDebtAave() private {
        uint256 max = 2**256 - 1;   //supposed to use uint(-1) not sure why that errors
        IERC20(aUSDC).approve(address(PoolAddress), max);
        Pool(PoolAddress).repay(aUSDC, max, interestRateMode, address(this));
    }

    function getAPYs() private returns(uint256, uint256) {
        uint256 RAY = 10**27;
        uint256 SECONDS_PER_YEAR = 31536000;
        uint128 liquidityRate = Pool(PoolAddress).getReserveData(USDC).currentLiquidityRate;
        uint128 currentStableBorrowRate = Pool(PoolAddress).getReserveData(USDC).currentStableBorrowRate;

        // Deposit and Borrow calculations
        // APY and APR are returned here as decimals, multiply by 100 to get the percents

        uint256 depositAPR = liquidityRate/RAY;
        uint256 stableBorrowAPR = currentStableBorrowRate/RAY;

        uint256 depositAPY = ((1 + (depositAPR / SECONDS_PER_YEAR)) ^ SECONDS_PER_YEAR) - 1;
        uint256 stableBorrowAPY = ((1 + (stableBorrowAPR / SECONDS_PER_YEAR)) ^ SECONDS_PER_YEAR) - 1;

        return(depositAPY, stableBorrowAPY);
    }


    // Loops supplying and borrowing to Aave when supply APY > borrow APY
    function _looping() private {
        uint256 depositAPY;
        uint256 borrowAPY;
        while (true) {    
            (depositAPY, borrowAPY) = getAPYs();
            if (borrowAPY > depositAPY) {
                uint256 amount = IERC20(aUSDC).balanceOf(address(this));
                _repayDebtAave();
                _supplyToAave(amount);
                _borrowFromAave(amount);
            }
        }
    }
}
