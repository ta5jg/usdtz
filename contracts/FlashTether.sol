// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    uint256 public usdtExchangeRate;
    uint256 public transactionFeePercentage;
    address public admin;
    address public paymentWallet;
    address public feeWallet;
    string public logoURI;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) public blacklisted;

    event PriceUpdated(uint256 newPrice);
    event ExchangeRateUpdated(uint256 newExchangeRate);
    event LogoUpdated(string newLogoURI);
    event TokenPurchased(address indexed buyer, uint256 usdtAmount, uint256 tokensReceived);
    event TransferWithUSDValue(address indexed from, address indexed to, uint256 tokenAmount, uint256 usdValue);
    event FeeWalletUpdated(address newFeeWallet);
    event TransactionFeeUpdated(uint256 newFeePercentage);
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Blacklisted address");
        _;
    }

    constructor(
        uint256 initialSupply,
        uint256 _maxSupply,
        string memory initialLogoURI,
        address _paymentWallet,
        address _feeWallet,
        address _admin
    ) {
        require(initialSupply <= _maxSupply, "Exceeds max supply");
        totalSupply = initialSupply * (10 ** decimals);
        maxSupply = _maxSupply * (10 ** decimals);
        balances[_admin] = totalSupply;

        usdPricePerToken = 999800;
        usdtExchangeRate = 1000000;
        transactionFeePercentage = 100; // %1

        paymentWallet = _paymentWallet;
        feeWallet = _feeWallet;
        admin = _admin;
        logoURI = initialLogoURI;

        emit Transfer(address(0), _admin, totalSupply);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) external override notBlacklisted(msg.sender) returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");
        
        uint256 fee = (value * transactionFeePercentage) / 10000;
        balances[msg.sender] -= value;
        balances[feeWallet] += fee;
        balances[to] += (value - fee);

        emit Transfer(msg.sender, feeWallet, fee);
        emit Transfer(msg.sender, to, value - fee);
        emit TransferWithUSDValue(msg.sender, to, value, (value * usdPricePerToken) / (10 ** decimals));
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowed[owner][spender];
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
        emit TransferWithUSDValue(from, to, value, (value * usdPricePerToken) / (10 ** decimals));
        return true;
    }

    // Yönetici Fonksiyonları
    function setUSDPrice(uint256 _newPrice) external onlyAdmin {
        usdPricePerToken = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    function setUSDTExchangeRate(uint256 _newRate) external onlyAdmin {
        usdtExchangeRate = _newRate;
        emit ExchangeRateUpdated(_newRate);
    }

    function setTransactionFee(uint256 _newFeePercentage) external onlyAdmin {
        require(_newFeePercentage <= 1000, "Max 10%");
        transactionFeePercentage = _newFeePercentage;
        emit TransactionFeeUpdated(_newFeePercentage);
    }

    function blacklist(address account) external onlyAdmin {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function whitelist(address account) external onlyAdmin {
        blacklisted[account] = false;
        emit Whitelisted(account);
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        require(totalSupply + amount <= maxSupply, "Exceeds max supply");
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external onlyAdmin {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}