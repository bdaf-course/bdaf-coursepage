# BDaF 2025 Almost everything can be a VAULT

- Deadline: April 25th (Friday midnight 23:59)
- Submission: 

## Overview

### Basic Idea of the Vault
You're writing a vault - a very common pattern in Defi that custodies people's funds. The vault simply allow people to deposit and withdraw anytime with the expectation that users' funds will grow (or decrease) proportionally according to the assets that are stored in the vault.

Here's an example to illustrate the idea:
> 1. A vault is empty.
> 2. Alice deposits into vault 100 USDC
>     - the vault has 100 USDC.
> 3. Bob 100 USDC
>     - the vault has 200 USDC.
> 4. Some entity "donates" 100 USDC into the vault
>     - the vault has 300 USDC.
> 5. Alice withdraws her shares, she gets 150 USDC
>     - Vault has 150 USDC.
> 6. Bob withdraws half of his shares, he gets 75 USDC. 
>     - There is still 75 USDC in the vault.

This is commonly being implemented with the concept of "shares", and often times it is issued as ERC20 token when funds are deposited. 

Let's expand the example above to get the idea of shares:

> 1. A vault is empty.
> 2. Alice deposits into vault 100 USDC
>     - the vault has 100 USDC.
>     - vault issues 100 shares to Alice.
> 3. Bob 100 USDC
>     - the vault has 200 USDC.
>     - vault issues 100 shares to Bob.
> 4. Some entity "donates" 100 USDC into the vault
>     - the vault has 300 USDC.
>     - NO shares were issued, someone just donated (transferred directly without using the deposit)
> 5. Alice withdraws her shares, she gets 150 USDC
>     - Vault has 150 USDC.
>     - Alice's 100 shares are burnt
> 6. Bob withdraws half of his shares, he gets 75 USDC. 
>     - Bob's 50 shares are burnt, he still has 50 shares.
>     - There is still 75 USDC in the vault. 


Now as you may have noticed, the value of one share can be different according to the amount of funds held in the contract. So if a third person comes in and deposit later, the vault should issue shares according to the price of share.

> 
> (Continued from the example above)
>
> 7. Carol deposits 75 USDC
>     - the vault issues 50 shares to Carol
>     - the vault has 150 USDC.
> 
> Final State overview:
> - Alice has 150 USDC
> - Bob has 75 USDC and 50 vault shares
> - Carol has 50 vault shares
> - vault has 100 shares issued in total and custodies 150 USDC. The price of a share is `150/100 = 1.5`.
>

There is a [EIP-4626, the vault standard](https://eips.ethereum.org/EIPS/eip-4626) that people have standardized. 

For the assignment's sake, you don't need to follow it (it contains more interface than needed to complete the assignment and complicates the implementation) - it is provided here as a reference and your knowledge.

### Money sitting untouched is uselss - Basic Vault and opportunity structure.

In the example above, we assumed that someone donated money to the vault. This is almost never the case. Money needs to be used to generate yield.

So we need to take away the money from the vault and "do something with it". We'll also need to maintain the price of share when the funds are being taken away, and even reflect the current value accrual if possible.

This is not part of the assignment, but extremely important concept.

### Project Requirement

## Part 1: A donation only vault - basically useless

Someone thinks it's a good idea to build a vault that does nothing and expect people to donate into it. Additionally, they want a function of `takeFeeAsOwner()` so that they can take money from the funds. You think it's a dumb idea and there are certainly security risk but they pay so you are developing the contract for them.

Your vault should have these interface:
> - address public underlyingToken: this is the token that the vault receives
> - uint256 public sharePrice: this is the price of 1 share compared t
> - function deposit(uint256 _amountUnderlying): takes the funds from the user and issues 
> - function withdraw(uint256 _amountShares): burns the specified shares and returns back the underlying token.
> - function takeFeeAsOwner(uint256 _amountUnderlying): this transfers money to the owner of the contract and can only be invoked by the owner.

note `takeFeeAsOwner()` is not a typical concept and only here per the design request.

sharePrice should properly reflect the value of each shares with respect to the tokens that are sitting in the vault, and your tests should verify this.

## Part 2: Wait, this can be attacked?

There is an inherent risk of vault structure, due to loss of precision. Luckily, this can only be applied when the vault is empty. Read here for the details. 

Read these: 
- [Inflation attack by mixBytes](https://mixbytes.io/blog/overview-of-the-inflation-attack)
- [Security concern of ERC-4626 - inflation attack](https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack)

Your goal for part 2 is write a test that demonstrates this attack.
> - Deployer deploys the vault contract empty
> - Malice attacks the contract
> - Bob deposits 100 tokens, but receives no shares
> - Malice withdraws with more tokens (basically Bob's token)

### Deliverables
- A super basic vault contract
- A complete test suite 
  - on top of all the unit tests that tests all the functionalities, test the example illustrated in the overview
- An additional test that demonstrates the inflation attack
- Answer the question and write a test to demonstrate it: what is the security risk of `takeFeeAsOwner()`?
- A proper documentation and a well written README on how to run the test

