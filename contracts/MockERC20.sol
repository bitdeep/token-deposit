// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockERC20 is ERC20 {
    constructor(uint _amount) ERC20("test", "test") {
        _mint(msg.sender, _amount);
    }
    function mint(address to, uint _amount) external{
        _mint(to, _amount);
    }
}
