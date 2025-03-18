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
    uint256 public transactionFeePercentage;
    address public feeWallet;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) public blacklisted;

    event TokenPurchased(address indexed buyer, uint256 usdtAmount, uint256 tokensReceived);
    event TransferWithUSDValue(address indexed from, address indexed to, uint256 tokenAmount, uint256 usdValue);
    event FeeWalletUpdated(address newFeeWallet);
    event TransactionFeeUpdated(uint256 newFeePercentage);
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);

        require(initialSupply <= _maxSupply, "Exceeds max supply");
        totalSupply = initialSupply * (10 ** decimals);
        maxSupply = _maxSupply * (10 ** decimals);
        feeWallet = _feeWallet;
    }

    }

        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        balances[feeWallet] += fee;
        balances[to] += (value - fee);
        emit Transfer(msg.sender, feeWallet, fee);
        emit Transfer(msg.sender, to, value - fee);
        return true;
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

    }

    }

    }

        blacklisted[account] = true;
        emit Blacklisted(account);
    }

        blacklisted[account] = false;
        emit Whitelisted(account);
    }

    }

    }
}