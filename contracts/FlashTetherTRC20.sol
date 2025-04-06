// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/AggregatorV3Interface.sol";

contract FlashTetherTRC20 is ERC20, Ownable, Pausable, ReentrancyGuard {
    uint8 private _decimals = 6;
    uint256 public maxSupply = 50_000_000_000 * (10 ** _decimals);
    bool public maxSupplyFrozen = false;

    address public feeWallet;
    address public treasuryWallet;
    address public usdtAddress;
    address public usdcAddress;
    AggregatorV3Interface public priceFeed;

    uint256 public fixedUSDPrice = 1e8;

    constructor(
        string memory name_,
        string memory symbol_,
        address _feeWallet,
        address _usdtAddress,
        address _usdcAddress,
        address _priceFeed
    ) ERC20(name_, symbol_) Ownable() {
        feeWallet = _feeWallet;
        treasuryWallet = msg.sender;
        usdtAddress = _usdtAddress;
        usdcAddress = _usdcAddress;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        uint256 scaledAmount = amount * (10 ** _decimals);
        require(totalSupply() + scaledAmount <= maxSupply, "Exceeds max supply");
        _mint(to, scaledAmount);
    }

    function usdValue(uint256 tokenAmount) public view returns (uint256) {
        return (fixedUSDPrice * tokenAmount) / (10 ** _decimals);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function liveUSDValue(uint256 tokenAmount) public view returns (uint256) {
        int256 price = getLatestPrice();
        require(price > 0, "Invalid price");
        return (uint256(price) * tokenAmount) / (10 ** _decimals);
    }

    function setFixedUSDPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than zero");
        fixedUSDPrice = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(!maxSupplyFrozen, "Max supply is frozen");
        require(newMaxSupply >= totalSupply(), "New max supply must be >= total supply");
        maxSupply = newMaxSupply;
    }

    function freezeMaxSupply() external onlyOwner {
        maxSupplyFrozen = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _customTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        _customTransfer(sender, recipient, amount);
        return true;
    }

    function _customTransfer(address sender, address recipient, uint256 amount) internal whenNotPaused nonReentrant {
        uint256 fee = (amount * 1) / 100;
        uint256 amountAfterFee = amount - fee;

        _transfer(sender, feeWallet, fee);
        _transfer(sender, recipient, amountAfterFee);
    }

    function setTreasuryWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid address");
        treasuryWallet = _wallet;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function name() public view override returns (string memory) {
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        return super.symbol();
    }
}