# BDaF 2025 Lab02 Peer to Peer Token Trade

- Deadline: March 10th, 18:30 before the lecture!
- Submission: 

## Readings
  - ERC20
    - [ERC20 OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20)
  - Zircuit Related
    - [Zircuit RPC](https://docs.zircuit.com/dev-tools/rpc-endpoints)
    - [Verify on Zircuit](https://docs.zircuit.com/dev-tools/verifying-contracts)

## Project Overview

A peer-to-peer ERC20 trading smart contract that allows users to create time-limited trade offers and others to fulfill them before expiry. The contract enforces trade validity, emits events for creation and settlement, charges a 0.1% fee on successful trades, and enables the owner to withdraw accumulated fees.

### Contract Requirement

Create TWO ERC20 tokens with: 
- total supply of 100,000,000 
- with 18 decimals
- Name them differently!

Create a token trade contract that:
- the deployer will set the two tokens that the contract is working with
- any user can set up trade with the interface: `setupTrade(address inputTokenForSale, uint256 inputTokenAmount, uint256 outputTokenAsk, uint256 expiry)`
  - this should emit an event. Think about what should be included in the event. 
- any user can fulfill the trade with the interface `settleTrade(uint256 id)` as long as the trade is not expired
  - this should emit an event.  Think about what should be included in the event. 
- expired trade should not be able to be fulfilled, and should allow the original user to retain his/her tokens.
- for all trades, the owner should get 0.1% fee the sale.
- there should be a function `withdrawFee()` that can be accessed by the owner only and can get all the fee accumulated in the contract. 


### Project Requirement
- Project MUST use either hardhat or foundry as framework
- Tests must be present and tests the requirements listed above.
- Tests should pass.
  - TA should be able to run it via `npx hardhat test` (hardhat) or `forge test` (foundry)
- Both contracts should be deployed on Zircuit (record the addresses)
- Both contract should be verified
- Execute the full flow of the token lock contract above on chain, we will ask for transaction hashes of the following:
  - Alice sets up trade
  - Bob settles trade
  - Owner withdraw fee