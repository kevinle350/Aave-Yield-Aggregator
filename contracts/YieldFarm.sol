//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external virtual override;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) public virtual override;
    function withdraw(address asset, uint256 amount, address to) public virtual override returns (uint256);
    function getConfiguration(address asset) external view virtual override returns (DataTypes.ReserveConfigurationMap memory);
}

contract YieldFarm {
    address private pool = 0x73A92E2b1Ec50bdf58aD5A2F6FAFB07d7D00E034;
    address private USDC = 0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f;
    uint private refferalCode = 0;
    uint private interestRateMode = 1;  //stable: 1, variable:2
    address owner;
    mapping(address => uint) public stakingBalance;

    constructor() {
        owner = msg.sender;
    }


    // User deposits USDC into to this contract address -> USDC turns to aUSDC to be stored on this conract -> This contract does the work 

    // User deposits USDC into to this contract address
    function stakeUSDC(uint _amount) public {
        require(_amount > 0, "Amount should be greater than zero");
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
    }

    // USDC turns to aUSDC to be stored on this contract
    function supplyUSDCtoAave() private {
        uint depositedUSDC = stakingBalance[msg.sender];
        uint contractUSDC = IERC20(USDC).balanceOf(address(this));
        require(depositedUSDC > 0, "Amount should be > than zero");
        require(contractUSDC >= depositedUSDC, "Total amount in contract should be >= than users deposit");
        Pool(pool).supply(USDC, depositedUSDC, address(this), refferalCode); 
    }

    // Borrow USDC using the underlying aUSDC(from user to contract) 
    // @Issues: how to get max collateral to borrow 
    function borrowUSDC() private {
        // uint withdrawnUSDC = Pool(pool).withdraw(USDC, type(uint).max, msg.sender); 
        uint maxLTV = stakingBalance[msg.sender];       // maxLTV = [(sum of collateral)i x LTVi]/total Collateral
        require(depositedUSDC > maxLTV, "Must have supplied enough collateral");
        Pool(pool).borrow(USDC, maxLTV, interestRateMode, refferalCode, address(this));
    }

    // User Withdraws their USDC + rewards
    function unstakeUSDC() public {
        uint balance = stakingBalance[msg.sender];
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(balance > 0, "Amount shoud be greater than zero");
        IERC20(USDC).transferFrom(address(this), msg.sender, balance);
    }

}