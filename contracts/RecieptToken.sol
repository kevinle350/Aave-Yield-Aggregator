//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RecieptToken is ERC20 {
    address public admin;
    constructor() ERC20("RecieptToken", "kUSDC") {
        _mint(msg.sender, 10000);
        admin = msg.sender;
    }

    function mintkUSDC(address _to, uint _amount) external {
        // require(msg.sender == admin, 'only admin');
        _mint(_to, _amount);
    }

    function burnkUSDC(address _to, uint _amount) external {
        _burn(_to, _amount);
    }

    function transferkUSDC(address _to, uint _amount) external {
        transfer(_to, _amount);
    }

    function userBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }
}