// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GEEKZNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    string public constant TOKEN_URI = "ipfs://QmXYAzy5NLJvwVCjMJ9pCZ2GF89wk4bGwyqZziEPk1ukKy";

    constructor() ERC721("Geekz Angelz NFT", "GEEKZVIP") Ownable(msg.sender) {}

    function safeMint(address to) public onlyOwner returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        require(tokenId < 100, "Max supply is 100 NFTs");   
        _tokenIdCounter += 1;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return TOKEN_URI;
    }
}