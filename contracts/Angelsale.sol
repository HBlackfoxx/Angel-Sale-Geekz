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
    IERC20G public usdt = IERC20G(0x55d398326f99059fF775485246999027B3197955); // Address should be set to USDT contract
    IERC20G public geekzToken = IERC20G(0x035f61905dDC716e34c8C3A26a81950C993245A2); // Address should be set to GeekzToken contract
    IERC721G public geekzNFT = IERC721G(0xD628f36fef90F20b8a4EAda64D1baD5aA2d7dee4); // Address should be set to your NFT contract

    address public paymentReceiver = 0xFd739c94B179A9376fb5dd22CF9CC61a853fFF26; // Address for receiving payments

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
        require(!presaleStarted, "Angelsale already started");
        presaleStarted = true;
        geekzToken.safeTransferFrom(_msgSender(),address(this), tokenPerSale * maxSales);
    }

    function stopPresale() external onlyOwner {
        require(!presaleClosed, "Angelsale already closed");
        presaleClosed = true;
    }

    function changeFundReceiver(address _paymentReceiver) external onlyOwner{
        paymentReceiver =_paymentReceiver;
    }

    function setBlacklist(address _addr,bool _state) external onlyOwner{
        isBlacklist[_addr]=_state;
    }

    function WithdrawRemainingTokens() external onlyOwner{
        require(presaleClosed,"Angelsale: Angelsale is not closed yet");
        geekzToken.safeTransfer(owner(), geekzToken.balanceOf(address(this)));
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20G Tokenadd = IERC20G(tokenAddress);
        require(Tokenadd != geekzToken, "You cannot recover Angelsale token");
        Tokenadd.transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
