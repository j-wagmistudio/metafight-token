// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   __  ________________   _______________ ________
//   /  |/  / __/_  __/ _ | / __/  _/ ___/ // /_  __/
//  / /|_/ / _/  / / / __ |/ _/_/ // (_ / _  / / /   
// /_/  /_/___/ /_/ /_/ |_/_/ /___/\___/_//_/ /_/    
//
contract MetafightToken is ERC20, Ownable, Pausable {

    /**
     * @dev max supply 100M tokens with 18 decimals
     */
    uint256 public constant MAX_SUPPLY = (10 ** 8) * (10 ** 18);

    /**
     * @dev max date range for vesting
     */
    uint256 private constant FIVE_YEARS_IN_SECONDS = 31557600 * 5;

    /**
     * @dev max vestings data for single address
     */
    uint256 private constant MAX_VESTINGS_ARRAY_LENGTH = 30;

    /**
     * @dev to allow other contracts to transfer tokens with a vesting period
     */
    mapping(address => bool) public sellers;

    /**
     * @dev vestings infos by token owners
     */
    mapping(address => uint256[]) private usersVestings;

    constructor(address contractOwner)
        ERC20("METAFIGHT TOKEN", "METAFIGHT TOKEN")
        Ownable(contractOwner)
        {
            _mint(contractOwner, MAX_SUPPLY);
        }

    //ADMIN FUNCTIONS

    /**
     * @dev allow admin to pause transfers that create new vesting periods
     */
    function switchPause(bool isPause) external onlyOwner {
        if(isPause){
            _pause();
            return;
        }
        _unpause();
    }

    /**
     * @dev allow an address to transfer tokens with a vesting period
     */
    function setSeller(address seller, bool isSeller) external onlyOwner {
        sellers[seller] = isSeller;
    }

    // VESTING FUNCTION

    /**
     * @dev transfer tokens to given account with vesting period
     */
    function transferWithVesting(address account, uint112 amount, uint48 startDate, uint48 endDate, uint48 cliffDate) external whenNotPaused {
        require(sellers[_msgSender()], "sender is not a seller");
        require(startDate <= cliffDate && cliffDate <= endDate, "invalid dates");
        require(endDate < block.timestamp + FIVE_YEARS_IN_SECONDS, "end date too far");
        require(usersVestings[account].length < MAX_VESTINGS_ARRAY_LENGTH,"too many vesting datas for this account");
        uint256 newVesting = _compressVestingAmountAndDates(amount, startDate, endDate, cliffDate);
        usersVestings[account].push(newVesting);
        _transfer(_msgSender(), account, amount);
    }

    /**
     * @dev returns given address vesting periods data (amount and dates)
     */
    function getUserVestings(address userAddress) external view returns (uint256[] memory) {
        return usersVestings[userAddress];
    }

    /**
     * @dev returns the amount of current blocked tokens for given address based on the block.timestamp
     */
    function getVestingTokenAmount(address userAddress) public view returns (uint256) {
        uint256[] memory vestings = usersVestings[userAddress];
        //unchecked block, checks done in the transferWithVesting function
        uint256 amount = 0;
        unchecked {
            uint256 currentBlockTime = block.timestamp;
            for(uint256 i=0;i<vestings.length;i++){
                uint256 vestingAmountAndDates = vestings[i];
                (uint256 vestingAmount, uint256 startDate, uint256 endDate, uint256 cliffDate) = _extractVestingAmountAndDates(vestingAmountAndDates);
                if(currentBlockTime < cliffDate) {
                    amount = amount + vestingAmount;
                    continue;
                }
                if(currentBlockTime >= endDate) {
                    continue;
                }
                amount = amount + (((endDate - currentBlockTime) * vestingAmount) / (endDate - startDate));         
            }
        }
       return amount;
    }

    //TOKEN TRANSFER VESTING CHECKS

    /**
     * @dev override ERC20 update function to add vesting period checks
     */
    function _update(address _from, address _to, uint256 _value) internal override {
        _checkBeforeUpdate(_from, _value);
        ERC20._update(_from, _to, _value);
    }

    //UTILS

    /**
     * @dev compress vesting period data in a single uint256
     *
     * compress the four following values :
     * - amount (can't exceed 2^112, bounded by MAX_SUPPLY)
     * - startDate (can't be greater than current timestamp in seconds + 5years)
     * - endDate (can't be greater than current timestamp in seconds + 5years)
     * - cliffDate (can't be greater than current timestamp in seconds + 5years)
     */
    function _compressVestingAmountAndDates(uint112 _amount, uint48 _startDate, uint48 _endDate, uint48 _cliffDate) internal pure returns (uint256) {
        uint256 startEndCliffDates = _amount + (uint256(_startDate) << 112) + (uint256(_endDate) << 160) + (uint256(_cliffDate) << 208);
        return startEndCliffDates;
    }

    /**
     * @dev extract the four values from compress fonction above
     */
    function _extractVestingAmountAndDates(uint256 _vestingAmountAndDates) internal pure returns (uint256, uint256, uint256, uint256) {
        uint112 amount = uint112(_vestingAmountAndDates);
        uint48 startDate = uint48(_vestingAmountAndDates >> 112);
        uint48 endDate = uint48(_vestingAmountAndDates >> 160);
        uint48 cliffDate = uint48(_vestingAmountAndDates >> 208);
        return (uint256(amount), uint256(startDate), uint256(endDate), uint256(cliffDate));
    }

    /**
     * @dev checks _from balance and vesting periods before a token transfer
     */
    function _checkBeforeUpdate(address _from, uint256 _value) internal {
        if(usersVestings[_from].length > 0) {
            uint256 vestingTokensAmount = getVestingTokenAmount(_from);
            if(vestingTokensAmount == 0) {
                delete(usersVestings[_from]);
                return;
            }
            uint256 fromBalance = balanceOf(_from) - vestingTokensAmount;
            if (fromBalance < _value) {
                revert ERC20InsufficientBalance(_from, fromBalance, _value);
            }
        }
    }

}