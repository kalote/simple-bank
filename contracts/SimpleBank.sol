// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IMyToken is IERC20 {
  function mint(address to, uint256 amount) external;
}

contract SimpleBank {
  // bank owner
  address public owner;

  // available currencies
  mapping(string => bool) public checkCurrencies;

  // Currency struct
  struct Currency {
    string code;
    IMyToken location;
    AggregatorV3Interface priceFeed;
  }

  // list of currencies
  Currency[] public currencies;

  // registered clients
  mapping(address => bool) public registered;

  // balances for each currencies
  mapping(address => mapping(string => uint)) internal balances;

  constructor(IMyToken _eurContract, IMyToken _usdContract, IMyToken _gbpContract, AggregatorV3Interface _eurPrice, AggregatorV3Interface _usdPrice, AggregatorV3Interface _gbpPrice) {
    owner = msg.sender;
    // make the owner the first registered client of our bank
    registered[owner] = true;
    // initialize default currencies
    currencies.push(Currency({
      code: "EUR",
      location: _eurContract,
      priceFeed: AggregatorV3Interface(_eurPrice)
    }));
    currencies.push(Currency({
      code: "USD",
      location: _usdContract,
      priceFeed: AggregatorV3Interface(_usdPrice)
    }));
    currencies.push(Currency({
      code: "GBP",
      location: _gbpContract,
      priceFeed: AggregatorV3Interface(_gbpPrice)
    }));
    // initialize checkCurrencies mapping
    checkCurrencies["EUR"] = true;
    checkCurrencies["USD"] = true;
    checkCurrencies["GBP"] = true;
  }
  
  /**
  * MODIFIERS
  */

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can use this function");
    _;
  }

  modifier onlyRegistered() {
    require(registered[msg.sender], "Only registered clients can use this function");
    _;
  }

  modifier onlyExistingCurrencies(string memory currency) {
    require(checkCurrencies[currency], "Currency not available");
    _;
  }

  /**
  * EVENTS
  */

  event LogRegister(address accountAddress);
  event LogDeposit(address accountAddress, string currency, uint amount);
  event LogWithdraw(address accountAddress, string currency, uint amount);
  event LogBuyToken(address accountAddress, string currency, uint amountGiven, uint amountReceive);

  /**
  * FUNCTIONS
  */

  function getBalance(string memory currency) 
    onlyRegistered 
    public view returns (uint) {
      return balances[msg.sender][currency];
  }

  function deposit(string memory currency, uint amount) 
    onlyRegistered 
    onlyExistingCurrencies(currency) 
    public returns (uint) {
      balances[msg.sender][currency] += amount;
      emit LogDeposit(msg.sender, currency, amount);
      return balances[msg.sender][currency];
  }

  function withdraw(string memory currency, uint amount)
    onlyRegistered
    onlyExistingCurrencies(currency)
    public returns (uint) {
      require(balances[msg.sender][currency] >= amount, "Not enough fund");
      balances[msg.sender][currency] -= amount;
      emit LogWithdraw(msg.sender, currency, amount);
      return balances[msg.sender][currency];
    }

  function register()
    public returns (bool) {
      registered[msg.sender] = true;
      emit LogRegister(msg.sender);
      return true;
    }

  function addNewCurrency(string memory _code, IMyToken _newCurrency, AggregatorV3Interface _priceFeed)
    onlyOwner
    public returns (bool) {
      currencies.push(Currency({
        code: _code,
        location: _newCurrency,
        priceFeed: _priceFeed
      }));
      checkCurrencies[_code] = true;
      return true;
    }

  // Function to buy tokens (EUR, USD, ...) with ETH
  // Uses chainlink oracle to get price of corresponding pair
  function buyTokens(string memory _currency)
    onlyExistingCurrencies(_currency)
    public payable 
    returns (uint amountToBeGiven) {
      uint256 paymentReceived = msg.value;
      for (uint256 i = 0; i < currencies.length; i++) {
        if (keccak256(bytes(currencies[i].code)) == keccak256(bytes(_currency))) {
          (,int price,,,) = currencies[i].priceFeed.latestRoundData();
          amountToBeGiven = paymentReceived * uint(price) / 1 ether;
          currencies[i].location.mint(msg.sender, amountToBeGiven);
          emit LogBuyToken(msg.sender, _currency, msg.value, amountToBeGiven);
        }
      }
  }
}
