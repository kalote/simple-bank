// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IMyToken is IERC20, IERC20Metadata {
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
    IMyToken fiatToken;
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
      fiatToken: _eurContract,
      priceFeed: AggregatorV3Interface(_eurPrice)
    }));
    currencies.push(Currency({
      code: "USD",
      fiatToken: _usdContract,
      priceFeed: AggregatorV3Interface(_usdPrice)
    }));
    currencies.push(Currency({
      code: "GBP",
      fiatToken: _gbpContract,
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
        fiatToken: _newCurrency,
        priceFeed: AggregatorV3Interface(_priceFeed)
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
      require(msg.value > 0, "You need to send ETH");
      int paymentReceived = int(msg.value);
      // loop through currencies to find the good one
      for (uint i = 0; i < currencies.length; i++) {
        // when we found the currency the sender wants to buy
        if (keccak256(bytes(currencies[i].code)) == keccak256(bytes(_currency))) {
          // we get the latest price
          (,int price,,,) = currencies[i].priceFeed.latestRoundData();
          // we get the # of decimals for this currency
          uint8 priceDecimals = currencies[i].priceFeed.decimals();
          // we scale the price (== same amount of decimals)
          price = scalePrice(price, priceDecimals, currencies[i].fiatToken.decimals());
          // we get the value of 1 of the currency with the same amount of decimals
          int decimals = int(10 ** uint256(currencies[i].fiatToken.decimals()));

          // we calculate the conversion between token / eth
          // if 0.1 eth given, and the user wants USD, then ~156.78 MyUSD will be given
          amountToBeGiven = uint256(paymentReceived * price / decimals);
          // we mint the appropriate amount of token to the sender
          currencies[i].fiatToken.mint(msg.sender, amountToBeGiven);
          // we log what happened
          emit LogBuyToken(msg.sender, _currency, msg.value, amountToBeGiven);
        }
      }
  }

  // internal scaling decimals function
  function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) 
    internal pure 
    returns (int256) {
      if (_priceDecimals < _decimals) {
        return _price * int256(10 ** uint256(_decimals - _priceDecimals));
      } else if (_priceDecimals > _decimals) {
        return _price / int256(10 ** uint256(_priceDecimals - _decimals));
      }
      return _price;
  }
}
