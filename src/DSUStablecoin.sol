// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {UsingTellor} from "usingtellor/contracts/UsingTellor.sol";

interface IPriceFeed {
    function latestAnswer() external view returns (int);
    function latestRoundData()
        external
        view
        returns (int, int256, int, uint256, int);
}

contract DSUStablecoin is ERC20, Ownable, ReentrancyGuard, UsingTellor {
    IPriceFeed public immutable priceFeed;
    address public immutable feeReceiver;
    address public constant BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public constant TRANSFER_FEE_BPS = 1; // 0.01% transfer fee in basis points
    
    // Fee exemption mapping for hooks and pools
    mapping(address => bool) public feeExempt;

    // For Tellor Price oracle
    bytes32 public immutable ethUsdQueryId;
    uint256 public constant DISPUTE_BUFFER = 20 minutes;
    uint256 public constant STALENESS_AGE = 1 hours;

    error StalePrice(uint256 price, uint256 timestamp);
    error NoValueRetrieved(uint256 timestamp);

    event Mint(address indexed to, uint256 dsuAmount);
    event BurnedETH(uint256 amount);
    event TransferFeeCollected(address indexed from, address indexed to, uint256 feeAmount, uint256 transferAmount);
    event FeeExemptionUpdated(address indexed account, bool exempt);

    constructor(
        address _priceFeedAddress,
        address _owner,
        address payable _tellorOracleAddress
    )
        ERC20("Decentralized Stable Unit", "DSU")
        Ownable(_owner)
        ReentrancyGuard()
        UsingTellor(_tellorOracleAddress)
    {
        priceFeed = IPriceFeed(_priceFeedAddress);
        feeReceiver = _owner;

        bytes memory _queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
        ethUsdQueryId = keccak256(_queryData);
    }

    function getPrice() public view returns (uint256) {
        // Try Chainlink first
        try priceFeed.latestRoundData() returns (
            int256 /*roundID*/,
            int256 answer,
            int256 /*startedAt*/,
            uint256 updatedAt,
            int256 /*answeredInRound*/
        ) {
            require(answer > 0, "Invalid price from Chainlink");
            require(block.timestamp - updatedAt <= 2 hours, "Chainlink price is stale");
            return uint256(answer);
        } catch {
            // fallback to Tellor if Chainlink fails
        }

        // Fallback to Tellor
        try this.getETHSpotPrice() returns (uint256 tellorPrice, uint256) {
            if (tellorPrice > 0) {
                return tellorPrice / 1e10;
            }
        } catch {
            revert("All price sources failed");
        }

        revert("All price sources failed");
    }

    function getETHSpotPrice()
        public
        view
        returns (uint256 _value, uint256 timestamp)
    {
        (bytes memory _data, uint256 _timestamp) = getDataBefore(
            ethUsdQueryId,
            block.timestamp - DISPUTE_BUFFER
        );

        if (_timestamp == 0 || _data.length == 0) revert NoValueRetrieved(_timestamp);

        _value = abi.decode(_data, (uint256));

        if (block.timestamp - _timestamp > STALENESS_AGE) {
            revert StalePrice(_value, _timestamp);
        }

        return (_value, _timestamp);
    }

    function calculateDsuAmount(uint256 amount) public view returns (uint256) {
        uint256 price = getPrice();
        return (amount * price) / 1e8;
    }

    function mintDSUWithETH() external payable nonReentrant {
        uint256 dsuAmount = calculateDsuAmount(msg.value);
        require(dsuAmount > 0, "Too small");

        uint256 feeAmount = msg.value / 10000;
        uint256 burnAmount = msg.value - feeAmount;

        (bool sentBurn, ) = BURN_ADDRESS.call{value: burnAmount}("");
        require(sentBurn, "Burn failed");

        (bool sentFee, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(sentFee, "Fee transfer failed");

        emit BurnedETH(burnAmount);

        _mint(msg.sender, dsuAmount);
        emit Mint(msg.sender, dsuAmount);
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        // Check if sender or recipient is fee exempt (hook/pool)
        if (feeExempt[_msgSender()] || feeExempt[to]) {
            return super.transfer(to, value);
        }
        
        uint256 feeAmount = value / 10000; // 0.01% transfer fee
        uint256 amountAfterFee = value - feeAmount;
        
        _transfer(_msgSender(), feeReceiver, feeAmount);
        _transfer(_msgSender(), to, amountAfterFee);
        
        emit TransferFeeCollected(_msgSender(), to, feeAmount, amountAfterFee);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        // Check if sender, recipient, or caller is fee exempt (hook/pool)
        if (feeExempt[from] || feeExempt[to] || feeExempt[_msgSender()]) {
            return super.transferFrom(from, to, value);
        }
        
        uint256 feeAmount = value / 10000; // 0.01% transfer fee
        uint256 amountAfterFee = value - feeAmount;

        _spendAllowance(from, _msgSender(), value);

        _transfer(from, feeReceiver, feeAmount);
        _transfer(from, to, amountAfterFee);
        
        emit TransferFeeCollected(from, to, feeAmount, amountAfterFee);
        return true;
    }

    /// @notice Set fee exemption status for hooks and pools
    /// @param account Address to exempt from transfer fees
    /// @param exempt True to exempt, false to remove exemption
    function setFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Invalid address");
        feeExempt[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }

    // Admin mint function for testnet - REMOVE FOR MAINNET
    function adminMint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        
        _mint(to, amount);
        emit Mint(to, amount);
    }
    
    // Batch mint for multiple addresses - useful for testnet setup
    function adminBatchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            _mint(recipients[i], amounts[i]);
            emit Mint(recipients[i], amounts[i]);
        }
    }

    function transferOwnership(address) public pure override {
        revert("transferOwnership is disabled");
    }

    receive() external payable {}
}