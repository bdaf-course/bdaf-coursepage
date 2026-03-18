# Onsite Lab O1: Build a DEX

## Overview

Build a simple decentralized exchange (DEX) for two ERC20 tokens with a **fixed exchange rate**.

Your DEX uses the invariant:

```
x + r * y = k
```

Where:
- `x` = reserve of token A
- `y` = reserve of token B
- `r` = exchange rate, set once at deployment
- `k` changes only when liquidity is added or removed

For example, if `r = 2`, then 1 unit of token B is worth 2 units of token A. The price never changes regardless of trade volume.

## Requirements

1. Deploy **two ERC20 tokens** on Zircuit Garfield testnet.
2. Build and deploy a **DEX contract** that:
   - Accepts the exchange rate `r` in the constructor
   - Allows users to add liquidity (any combination of token A and token B)
   - Allows users to swap token A for token B, and vice versa, at the fixed rate `r`
3. Your DEX must implement the following interface:

```solidity
interface IDEX {
    function addLiquidity(uint256 amountA, uint256 amountB) external;
    function swap(address tokenIn, uint256 amountIn) external;
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB);
    function feeRecipient() external view returns (address);
    function withdrawFee() external;
}
```

> For the base check, `feeRecipient()` can return `address(0)` and `withdrawFee()` can be a no-op. These are required for the bonus.

## Swap Math

Given the invariant `x + r * y = k`:

| Direction | Input | Output |
|-----------|-------|--------|
| A → B | `amountIn` of token A | `amountIn / r` of token B |
| B → A | `amountIn` of token B | `amountIn * r` of token A |

The invariant `k` must **never change** during a swap.

## Checker

The `OnSiteChecker` contract will verify your implementation by:

1. Adding liquidity to your DEX
2. Swapping A → B and B → A
3. Verifying the invariant `x + r * y = k` is preserved after every swap
4. Verifying reserves are consistent

### How to pass

1. Deploy your two tokens and DEX contract.
2. Transfer tokens to the `OnSiteChecker` contract. You need **at minimum**:
   - `110 * r` tokens of A (in wei, i.e. `110e18 * r`)
   - `110` tokens of B (in wei, i.e. `110e18`)
3. Call `OnSiteChecker.check(studentId, dex, tokenA, tokenB, rate)` with your student ID.

## Bonus: Fee Mechanism

FeeRecipient:  https://explorer.garfield-testnet.zircuit.com/address/0x3AD64ABb43D793025a2f2bD9d615fa1447008bFD
OnSiteChecker: https://explorer.garfield-testnet.zircuit.com/address/0xa6FF20737004fb2f632B6b9388C7731B871a201D

Implement a **0.1% fee** on every swap. The fee is deducted from the swap input before calculating the output.

### Rules

- Fee = `amountIn / 1000` (0.1% of input), taken in the input token
- Only the net amount (after fee) enters the pool reserves
- The invariant `x + r * y = k` must be preserved after every swap
- Accumulated fees are held in the contract **separately from reserves**
- A `feeRecipient` can withdraw accumulated fees without changing the invariant

### Fee Math

| Direction | Input | Fee | Net to pool | Output |
|-----------|-------|-----|-------------|--------|
| A → B | `amountIn` | `amountIn / 1000` | `amountIn * 999 / 1000` | `(amountIn * 999 / 1000) / r` |
| B → A | `amountIn` | `amountIn / 1000` | `amountIn * 999 / 1000` | `(amountIn * 999 / 1000) * r` |

### How to pass bonus

1. Deploy a fee-enabled DEX with `feeRecipient()` set to the `FeeRecipient` contract.
2. Transfer tokens to the `OnSiteChecker` contract. You need **at minimum**:
   - `3000 * r` tokens of A (in wei, i.e. `3000e18 * r`)
   - `3000` tokens of B (in wei, i.e. `3000e18`)
3. Call `OnSiteChecker.checkBonus(studentId, dex, tokenA, tokenB, rate)` with your student ID.

The bonus checker will:
1. Add liquidity and perform swaps
2. Verify output amounts reflect the 0.1% fee
3. Verify the invariant holds after each swap
4. Call `FeeRecipient.claimFee(dex)` to trigger fee withdrawal
5. Verify the feeRecipient received the correct fees
6. Verify the invariant still holds after fee withdrawal

### Deployed addresses

| Contract | Address |
|----------|---------|
| OnSiteChecker | `TBD` |
| FeeRecipient | `TBD` |

## Reference

- Zircuit Garfield Testnet Explorer: https://explorer.garfield-testnet.zircuit.com/
- Zircuit Docs: https://docs.zircuit.com/garfield-testnet/quick-start

## Think Further

Once you've passed the checker, ask yourself: **would you trust this DEX with your own money?** Is there anything missing?
