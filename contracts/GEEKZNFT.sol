// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GEEKZNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    string public constant TOKEN_URI = "ipfs://QmR9iv9wFgb7UBcYg5rhen771swnbxALZg1K6EfY7mTbTr";

    constructor() ERC721("Geekz", "GKZ") Ownable(msg.sender) {}

    function safeMint(address to) public onlyOwner returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        require(tokenId == 0, "Only one token can be minted");
        
        _tokenIdCounter += 1;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return TOKEN_URI;
    }
}