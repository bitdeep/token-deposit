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
    uint public depositFee; // 1000 = 10%
    uint public withdrawFee; // 1000 = 10%
    uint public totalFeeCollected;
    address public feeAddress;
    uint public balance;

    struct DepositInfo {
        address user;
        uint256 shares;
        uint256 deposited;
        uint256 datetime;
    }

    mapping(address => DepositInfo) public deposits;

    event Deposit(address user, uint shares);
    event Withdraw(address user, uint shares);

    error InvalidTokenAddress();
    error InvalidDepositAmount();
    error InvalidSharesAmount();
    error InvalidFeeAmount();
    error InvalidFeeAddress();

    constructor(address _token, uint _fee) ERC20("RCP", "Receipt") {
        if (_token == address(0))
            revert InvalidTokenAddress();
        token = IERC20(_token);
        token.totalSupply();
        depositFee = _fee;
        feeAddress = msg.sender;
    }

    function changeDepositFee(uint256 _fee) external onlyOwner {
        if (_fee > 10000)
            revert InvalidFeeAmount();
        depositFee = _fee;
    }
    function changeWithdrawFee(uint256 _fee) external onlyOwner {
        if (_fee > 10000)
            revert InvalidFeeAmount();
        withdrawFee = _fee;
    }

    function changeFeeAddress(address payable _address) external onlyOwner {
        if (_address == address(0x0))
            revert InvalidFeeAddress();
        feeAddress = _address;
    }

    function deposit(uint value) external {
        if (value == 0)
            revert InvalidDepositAmount();

        token.safeTransferFrom(msg.sender, address(this), value);

        if (depositFee > 0) {
            uint256 feeAmount = (value * depositFee) / 10000;
            token.safeTransfer(feeAddress, feeAmount);
            value -= feeAmount;
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

        DepositInfo storage depositInfo = deposits[msg.sender];

        depositInfo.user = msg.sender;
        depositInfo.shares += shares;
        depositInfo.deposited += value;
        depositInfo.datetime = block.timestamp;

        emit Deposit(msg.sender, shares);

    }

    function withdraw(uint shares) external {
        if (shares == 0)
            revert InvalidSharesAmount();

        uint256 supply = totalSupply();

        uint256 value = (balance * shares) / supply;
        balance -= value;
        _burn(msg.sender, shares);

        DepositInfo storage depositInfo = deposits[msg.sender];

        depositInfo.shares -= shares;
        depositInfo.deposited -= value;

        if (withdrawFee > 0) {
            uint256 feeAmount = (value * withdrawFee) / 10000;
            token.safeTransfer(feeAddress, feeAmount);
            value -= feeAmount;
            totalFeeCollected += feeAmount;
        }

        token.safeTransfer(msg.sender, value);

        emit Withdraw(msg.sender, shares);

    }

}
