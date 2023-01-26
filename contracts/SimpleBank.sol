// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SimpleBank {
  // bank owner
  address public owner;

  // available currencies
  mapping(string => bool) checkCurrencies;

  // list of currencies
  string[] currencies = ["EUR", "USD", "GBP"];

  // registered clients
  mapping(address => bool) registered;

  // balances for each currencies
  mapping(address => mapping(string => uint)) balances;

  constructor() {
    owner = msg.sender;
    // make the owner the first registered client of our bank
    registered[owner] = true;
    // initialize default currencies
    // extract length to avoid computation at each loop
    uint currenciesLength = currencies.length;
    for (uint i = 0; i < currenciesLength; i++) {
      checkCurrencies[currencies[i]] = true;
    }
  }
  
  /**
  * MODIFIERS
  */

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyRegistered() {
    require(registered[msg.sender]);
    _;
  }

  modifier onlyExistingCurrencies(string memory currency) {
    require(checkCurrencies[currency]);
    _;
  }

  /**
  * EVENTS
  */

  event LogRegister(address accountAddress);
  event LogDeposit(address accountAddress, string currency, uint amount);
  event LogWithdraw(address accountAddress, string currency, uint amount);

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

  function addNewCurrency(string memory code)
    onlyOwner
    public returns (bool) {
      currencies.push(code);
      checkCurrencies[code] = true;
      return true;
    }
}
