// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FlashTetherTRC20 is ITRC20 {
    string public name = "Flash Tether";
    string public symbol = "USDTz";
    uint8 public decimals = 6;
    uint256 public override totalSupply;
    uint256 public maxSupply;
    uint256 public usdPricePerToken;
    uint256 public transactionFeePercentage;

    address public owner;
    address public feeWallet;
    bool public paused;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public feeExempted;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Blacklisted address");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    bool private locked;

    event Paused(address account);
    event Unpaused(address account);
    event TokenPurchased(address indexed buyer, uint256 usdtAmount, uint256 tokensReceived);
    event TransferWithUSDValue(address indexed from, address indexed to, uint256 tokenAmount, uint256 usdValue);
    event FeeWalletUpdated(address newFeeWallet);
    event TransactionFeeUpdated(uint256 newFeePercentage);
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event EmergencyWithdraw(address indexed admin, uint256 amount);

    constructor(uint256 initialSupply, uint256 _maxSupply, address _feeWallet) {
        require(initialSupply <= _maxSupply, "Exceeds max supply");
        owner = msg.sender;
        totalSupply = initialSupply * (10 ** decimals);
        maxSupply = _maxSupply * (10 ** decimals);
        balances[owner] = totalSupply;
        transactionFeePercentage = 100;
        feeWallet = _feeWallet;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) external override whenNotPaused notBlacklisted(msg.sender) returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");
        uint256 fee = feeExempted[msg.sender] ? 0 : (value * transactionFeePercentage) / 10000;
        balances[msg.sender] -= value;
        balances[feeWallet] += fee;
        balances[to] += (value - fee);
        emit Transfer(msg.sender, feeWallet, fee);
        emit Transfer(msg.sender, to, value - fee);
        return true;
    }

    function buyToken(uint256 usdtAmount) external payable whenNotPaused nonReentrant {
        uint256 tokensToReceive = (usdtAmount * (10 ** decimals)) / usdPricePerToken;
        require(totalSupply + tokensToReceive <= maxSupply, "Exceeds max supply");
        balances[msg.sender] += tokensToReceive;
        totalSupply += tokensToReceive;
        emit TokenPurchased(msg.sender, usdtAmount, tokensToReceive);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(balances[from] >= value, "Insufficient balance");
        require(allowed[from][msg.sender] >= value, "Allowance exceeded");
        uint256 fee = (value * transactionFeePercentage) / 10000;
        balances[from] -= value;
        balances[feeWallet] += fee;
        balances[to] += (value - fee);
        allowed[from][msg.sender] -= value;
        emit Transfer(from, feeWallet, fee);
        emit Transfer(from, to, value - fee);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return allowed[_owner][spender];
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function blacklistAddress(address account) external onlyOwner {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function whitelistAddress(address account) external onlyOwner {
        blacklisted[account] = false;
        emit Whitelisted(account);
    }

    function updateFeeWallet(address newFeeWallet) external onlyOwner {
        feeWallet = newFeeWallet;
        emit FeeWalletUpdated(newFeeWallet);
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
        emit EmergencyWithdraw(owner, amount);
    }
}
