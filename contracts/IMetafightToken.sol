// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMetafightToken is IERC20 {

    function transferWithVesting(address account, uint112 amount, uint48 startDate, uint48 endDate, uint48 cliffDate) external;
    
}