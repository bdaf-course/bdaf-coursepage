# Onsite Lab 2: DeFi Exploit Lab

## Overview

Three DeFi protocols have been deployed on Ethereum Sepolia. Each protocol reads price data from an on-chain DEX to make financial decisions.

Your job: **find the vulnerability in each protocol and exploit it.**

Every student gets their own isolated set of contracts (DEX + 3 protocols). Your exploits won't affect other students.

## Getting Started

### 1. Register

Call `createInstance(studentId)` on the ChallengeFactory with your student ID. This deploys your personal contracts.

### 2. Find your contracts

After registration, query your instance from the factory:

```solidity
function instances(string studentId) external view returns (
    address wallet,
    address dex,
    address flashLoanPool, // Your capital source
    address lender,        // Challenge 1
    address liquidator,    // Challenge 2
    address rebalancer,    // Challenge 3
    address dummyBorrower,
    bool challenge1,
    bool challenge2,
    bool challenge3,
    bool bonus
);
```

### 3. Read the contracts

All contracts are **verified on Etherscan**. Read the source code carefully.

Key contracts to study:
- **SimpleDEX** — a constant-product AMM (`x * y = k`)
- **FlashLoanPool** — your capital source (flash loans)
- **VulnerableLender** — Challenge 1
- **VulnerableLiquidator** — Challenge 2
- **VulnerableRebalancer** — Challenge 3

### 4. Exploit

A **FlashLoanPool** is deployed for each student, funded with 50,000 of each token. You can borrow tokens with zero capital — as long as you return them within the same transaction.

```solidity
interface IFlashBorrower {
    function onFlashLoan(address token, uint256 amount, bytes calldata data) external;
}
```

To use a flash loan:
1. Deploy a contract that implements `IFlashBorrower`
2. Call `flashLoan(token, amount, data)` on the **FlashLoanPool**
3. The pool sends you the tokens, then calls your `onFlashLoan` callback
4. Do whatever you need inside the callback
5. Ensure the tokens are returned to the pool before `onFlashLoan` returns

### 5. Verify

After exploiting a protocol, call the corresponding check function on the factory:
- `check1(studentId)` — Challenge 1
- `check2(studentId)` — Challenge 2
- `check3(studentId)` — Challenge 3

If the check passes, your completion is recorded on-chain.

---

## Challenges

### Challenge 1: VulnerableLender (1 point)

A lending protocol where users deposit TokenA as collateral and borrow TokenB.

**Your goal:** Drain at least 50% of the lending pool's TokenB.

Relevant functions to study:
- `getPrice()`
- `depositAndBorrow(uint256 collateralAmount)`
- `flashLoan(address token, uint256 amount, bytes calldata data)`

### Challenge 2: VulnerableLiquidator (2 points)

A lending protocol with a liquidation mechanism. A dummy borrower already has an open position (deposited TokenA, borrowed TokenB). The position is healthy under normal conditions.

**Your goal:** Liquidate the dummy borrower's position.

Relevant functions to study:
- `getPrice()`
- `isHealthy(address user)`
- `liquidate(address borrower)`
- `flashLoan(address token, uint256 amount, bytes calldata data)`

The dummy borrower's address is stored in your factory instance.

### Challenge 3: VulnerableRebalancer (3 points)

A treasury management contract that maintains a balanced portfolio of TokenA and TokenB. Anyone can swap tokens with the treasury at the current market price.

**Your goal:** Reduce the treasury's total value by at least 10%.

Relevant functions to study:
- `getPrice()`
- `getTreasuryValue()`
- `swapAForB(uint256 amountIn)`
- `swapBForA(uint256 amountIn)`

---

## Scoring

| Challenge | Points |
|-----------|--------|
| Challenge 1 | 1 |
| Challenge 2 | 2 |
| Challenge 3 | 3 |
| **Total** | **6** |

---

## Deployed Addresses

| Contract | Address |
|----------|---------|
| ChallengeFactory | [`0x35c73628b4FaD218A2B0B24098D9E0B7CBB45eF7`](https://eth-sepolia.blockscout.com/address/0x35c73628b4FaD218A2B0B24098D9E0B7CBB45eF7) |
| TokenA (CTA) | [`0x52fddb524B9975c5CFC53fAd0C43B54807AB5B28`](https://eth-sepolia.blockscout.com/address/0x52fddb524B9975c5CFC53fAd0C43B54807AB5B28) |
| TokenB (CTB) | [`0xe2632E10Da25B80dcE5eE6965eF042FF9Ff29aec`](https://eth-sepolia.blockscout.com/address/0xe2632E10Da25B80dcE5eE6965eF042FF9Ff29aec) |

---

## Hints

- All three protocols share a common design pattern. What assumption are they making about price?
- The SimpleDEX uses the constant-product formula: `amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)`. Think about what happens to the price when someone makes a large swap.
- You don't need any starting capital. Flash loans give you everything you need.
- Each exploit can be done in a single transaction.

## Reference

- Ethereum Sepolia Explorer: https://sepolia.etherscan.io/
- Sepolia Faucet: https://cloud.google.com/application/web3/faucet/ethereum/sepolia
- Flash Loans explained: https://docs.aave.com/developers/guides/flash-loans
