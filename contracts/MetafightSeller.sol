// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMetafightToken.sol";

contract MetafightSeller is Ownable, Pausable {

    uint48 public startDate;

    uint48 public endDate;

    uint48 public cliffDate;

    IMetafightToken public collection;

    constructor(address owner, address metafightTokenContractAddress, uint48 _startDate, uint48 _endDate, uint48 _cliffDate)
        Ownable(owner)
        {
            collection = IMetafightToken(metafightTokenContractAddress);
            startDate = _startDate;
            endDate = _endDate;
            cliffDate = _cliffDate;
        }

    //ADMIN FUNCTIONS

    function switchPause(bool _isPause) external onlyOwner {
        if(_isPause){
            _pause();
            return;
        }
        _unpause();
    }

    //MINT FUNCTIONS

    function transferVestedTokens(address account, uint112 amount) external whenNotPaused {
        collection.transferWithVesting(account, amount, startDate, endDate, cliffDate);
    }

    function transferTokens(address account, uint112 amount) external whenNotPaused {
        collection.transfer(account, amount);
    }



  
}