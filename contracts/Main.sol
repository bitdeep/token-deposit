// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Main is Ownable, ERC20 {
    using SafeERC20 for IERC20;
    IERC20 public token;
    uint public fee = 1000; // 1000 = 10%
    uint public totalFeeCollected;
    address public feeAddress;
    uint public balance;

    struct DepositInfo {
        address user;
        uint256 shares;
        uint256 deposited;
        uint256 datetime;
    }

    mapping(address => DepositInfo[]) public deposits;

    event Deposit(address user, address shares);
    event Withdraw(address user, address shares);

    error InvalidTokenAddress();
    error InvalidDepositAmount();
    error InvalidSharesAmount();
    error InvalidFeeAmount();
    error InvalidFeeAddress();

    constructor(address _token, uint _multiplier) ERC20("RCP", "Receipt") {
        if (_token == address(0))
            revert InvalidTokenAddress();
        token = IERC20(_token);
        token.totalSupply();
        multiplier = _multiplier;
    }

    function changeFee(uint256 _fee) external onlyOwner {
        if (_fee > 10000)
            revert InvalidFeeAmount();
        fee = _fee;
    }

    function changeFeeAddress(address payable _address) external onlyOwner {
        if (_address == address(0x0))
            revert InvalidFeeAddress();
        feeAddress = _address;
    }

    function deposit(uint value) external {
        if (value == 0)
            revert InvalidDepositAmount();

        token.safeTransfer(address(this), value);

        if (fee > 0) {
            uint256 feeAmount = (value * fee) / 10000;
            token.safeTransfer(feeAddress, feeAmount);
            value = value - feeAmount;
            totalFeeCollected += feeAmount;
        }


        uint256 supply = totalSupply();

        uint shares;
        if (supply == 0 || balance == 0) {
            shares = value;
        } else {
            shares = (value * supply) / balance;
        }
        _mint(msg.sender, shares);

        balance += value;

        DepositInfo storage deposit = deposits[msg.sender];

        deposit.user = msg.sender;
        deposit.shares += shares;
        deposit.deposited += value;
        deposit.datetime = block.timestamp;

        emit Deposit(msg.sender, shares);

    }

    function withdraw(uint shares) external {
        if (shares == 0)
            revert InvalidSharesAmount();

        uint256 supply = totalSupply();

        uint256 value = (balance * shares) / supply;
        balance -= value;
        _burn(msg.sender, shares);

        DepositInfo storage deposit = deposits[msg.sender];

        deposit.shares -= shares;
        deposit.deposited -= value;

        emit Withdraw(msg.sender, shares);

    }

}
