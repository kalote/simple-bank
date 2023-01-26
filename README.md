# Simple Bank

This is an implementation of a simple bank contract: deposit / withdraw / get balance. The bank allows multiple currencies (default: USD, EUR, GBP), and the bank owner can add more if needed.

## Install

```
npm i
npx hardhat compile
npx hardhat test
```

## Deploy

```
touch .env # check the .env.example to see what values are expected
npx hardhat run scripts/deploy.ts --network goerli
```