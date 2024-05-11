// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

   /**
    * @title GEEKZ Token Contract
    * @dev Implementation of the GEEKZ Token, an ERC20 token with burn, permit, and ownable features,
    * along with an added tax and burn fees mechanism on transfers.
    */

contract GEEKZ is ERC20, ERC20Burnable, ERC20Permit, Ownable {

    mapping(address => bool) public isExcludedFromFees;
    address taxwallet = 0x36cBb6351CA992F058E587e900E85E54a76e2A98;

    /**
     * @dev Sets the initial values for the GEEKZ Token and mints initial supply to the contract owner.
     * Excludes the tax wallet from fees.
     */
    constructor() ERC20("GEEKZ", "GEEKZ") ERC20Permit("GEEKZ") Ownable(msg.sender) {
        _mint(owner(), (10 ** 15) * (10 ** decimals()));
        isExcludedFromFees[taxwallet] = true;
    }

    /**
     * @dev Overrides the _update function to add tax and burn fees logic to transfers.
     * Tax and burn fees are not applied to minting, burning, or addresses excluded from fees.
     * @param from Address tokens are being transferred from.
     * @param to Address tokens are being transferred to.
     * @param value Amount of tokens to transfer.
     */
    function _update(address from, address to, uint256 value) internal override  {
        if(from == address(0) || to == address(0) || isExcludedFromFees[from] || isExcludedFromFees[to]){
            super._update(from, to, value);
        }
        else{
            uint256 burnandtaxfee = value / 100;
            super._update(from, taxwallet, burnandtaxfee); 
            super._update(from, address(0), burnandtaxfee);
            super._update(from, to, value - 2 * burnandtaxfee);
        }
    }

    /**
     * @dev Allows the owner to exclude or include an address from transaction fees.
     * @param addressToCheck Address to be modified.
     * @param value True to exclude from fees, false to include.
     */
    function excludeFromFees(address addressToCheck, bool value) external onlyOwner {
        require(isExcludedFromFees[addressToCheck] != value, "Address is already set to this fee exclusion status");
        isExcludedFromFees[addressToCheck] = value;
    }

    /**
     * @dev Allows the owner to change the tax wallet address.
     * Automatically excludes the new tax wallet from fees.
     * @param newTaxWallet The new tax wallet address.
     */
    function changeTaxWallet(address newTaxWallet) external onlyOwner{
        require(taxwallet != newTaxWallet,"New tax wallet address must be different");
        isExcludedFromFees[taxwallet] = false;
        isExcludedFromFees[newTaxWallet] = true;
        taxwallet = newTaxWallet;
    }

    /**
     * @dev Checks if an address is excluded from fees.
     * @param addressToCheck The address to check.
     * @return bool True if the address is excluded from fees.
     */
    function isexcludedFromFees(address addressToCheck) external view returns(bool) {
        return isExcludedFromFees[addressToCheck];
    }
}
