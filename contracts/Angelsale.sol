// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC20G is IERC20{
    function decimals() external view returns (uint8);
}

interface IERC721G is IERC721 {
    function safeMint(address to) external returns (uint256 tokenId);
}

contract AngelSale is Ownable, IERC721Receiver {

    using SafeERC20 for IERC20G;

    mapping (address => bool) public isBlacklist;
    mapping (address => bool) public claimed;
    IERC20G public usdt = IERC20G(0xa29e9E81e1952d0c9b55C20017671eB505c3FCAD); // Address should be set to USDT contract
    IERC20G public geekzToken = IERC20G(0x0C344EE96232586f485fa4af4bAF851501cAD54A); // Address should be set to GeekzToken contract
    IERC721G public geekzNFT = IERC721G(0x36Cd40799d0710cd9bc70Bf84ffE7d588BE48074); // Address should be set to your NFT contract

    address public paymentReceiver = 0xbf3fd8b071BA8BA2191471500b45020872eb4dE0; // Address for receiving payments

    uint256 public  salePrice = 1000 * 10 ** usdt.decimals(); // 1000 USDT
    uint256 public  tokenPerSale = 100_000_000_000 * 10 ** geekzToken.decimals(); // 100 billion tokens
    uint256 public maxSales = 100;
    uint256 public saleCount;
    bool public presaleStarted;
    bool public presaleClosed;

    event Recovered(address token, uint256 amount);
    event Sale(address indexed buyer, uint256 amount, uint256 tokenId);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function buyWithUSDT() external {
        require(saleCount < maxSales, "Sale limit reached");
        require(!claimed[msg.sender], "Already claimed");
        require(isBlacklist[msg.sender] == false,"You are blacklisted");
        require(presaleStarted && !presaleClosed, "Sale is not active");
        require(tx.origin == msg.sender,"Caller is a contract");
        require(usdt.allowance(msg.sender, address(this)) >= salePrice, "Insufficient USDT allowance");

        saleCount++;
        claimed[msg.sender] = true;
        usdt.safeTransferFrom(msg.sender, paymentReceiver, salePrice);
        geekzToken.safeTransfer(msg.sender, tokenPerSale);

        uint256 tokenId = geekzNFT.safeMint(msg.sender);

        emit Sale(msg.sender, tokenPerSale, tokenId);
    }

    function startPresale() external onlyOwner {
        require(!presaleStarted, "Presale already started");
        presaleStarted = true;
        geekzToken.safeTransferFrom(_msgSender(),address(this), tokenPerSale * maxSales);
    }

    function stopPresale() external onlyOwner {
        require(!presaleClosed, "Presale already closed");
        presaleClosed = true;
    }

    function changeFundReceiver(address _paymentReceiver) external onlyOwner{
        paymentReceiver =_paymentReceiver;
    }

    function setBlacklist(address _addr,bool _state) external onlyOwner{
        isBlacklist[_addr]=_state;
    }

    function WithdrawRemainingTokens() external onlyOwner{
        require(presaleClosed,"Presale: Presale is not closed yet");
        geekzToken.safeTransfer(owner(), geekzToken.balanceOf(address(this)));
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20G Tokenadd = IERC20G(tokenAddress);
        require(Tokenadd != geekzToken, "You cannot recover Presale token");
        Tokenadd.transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
