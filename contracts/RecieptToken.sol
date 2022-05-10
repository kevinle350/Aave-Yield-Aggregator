//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RecieptToken is ERC20 {
    constructor() ERC20("RecieptToken", "kUSDC") {

    }

    function mintkUSDC(address _minter, uint _amount) public {
        _mint(_minter, _amount);
    }

    function burnkUSDC(address _minter, uint _amount) public {
        _burn(_minter, _amount);
    }
}