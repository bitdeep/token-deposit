// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Main is Ownable, ERC20 {
    IERC20 public token;
    uint public multiplier = 1;
    using SafeERC20 for IERC20;
    error InvalidTokenAddress();
    error InvalidDepositAmount();
    constructor(address _token, uint _multiplier) ERC20("RCP", "Receipt") {
        if (_token == address(0))
            revert InvalidTokenAddress();
        token = IERC20(_token);
        token.totalSupply();
        multiplier = _multiplier;
    }
    function deposit(uint amount) external {
        if (amount == 0)
            revert InvalidDepositAmount();

        token.safeTransfer(address(this), amount);
        _mint(msg.sender, amount * multiplier );
    }
}
