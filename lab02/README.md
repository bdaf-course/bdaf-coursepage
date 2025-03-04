# BDaF 2025 Lab02 Token Lock

- Deadline: March 11th 23:59 (1 week deadline!)
- Submission: 

## Readings
  - ERC20
    - [ERC20 OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20)
  - Zircuit Related
    - [Zircuit RPC](https://docs.zircuit.com/dev-tools/rpc-endpoints)
    - [Verify on Zircuit](https://docs.zircuit.com/dev-tools/verifying-contracts)

## Project Overview

You wanted to create a very simple option like contract - users are allowing you to trade against their funds during a given time for a predefined rate of the underlying asset. 

### Contract Requirement

Create an ERC20 token with: 
- total supply of 100,000,000 
- with 18 decimals

Create a token lock contract that:
- owner is able to set a start time and end time for token lock (`setStartTime(...)` and `setEndTime(...)`)
- any user can lock their ETH into the contract before the start time (`lock(...)`)
- any user can unlock their ETH from the contract after the end time (`unlock(...)`)
- when user unlock their ETH, they should also receive the designated reward as specified below
  - if their ETH was not taken, they get their ETH and the small reward
  - if their ETH was taken, they can still `unlock` and receive their reward
- before the start time and end time were set by the owner, no user should be able to lock their ETH.
- the owner can decide to trade tokens with the users' deposit (`tradeUserFunds(...)`)
- to reward people using your contract, you are going to use the ERC20 created above
  - any user who locked and able to withdraw: you reward them with 1,000 tokens
  - any user who locked and was not able to withdraw (essentially, the owner took their ETH): you reward them with 1000 + (ETH locked * 2500) tokens
- owner can withdraw ETH from the contract, but the source of funds should only come from the ETH they have traded using `tradeUserFunds()` and cannot exceed that (`getETH()`)

### Project Requirement
- Project MUST use either hardhat or foundry as framework
- Tests must be present and tests the requirements listed above.
- Tests should pass.
  - TA should be able to run it via `npx hardhat test` (hardhat) or `forge test` (foundry)
- Both contracts should be deployed on Zircuit (record the addresses)
- Both contract should be verified
- Execute the full flow of the token lock contract above on chain, we will ask for transaction hashes of the following:
  - a user (Alice) locking their ETH into the contract
  - Alice unlock their ETH and receives a small reward
  - another user (Bob) locking their ETH into the contract
  - owner executes `tradeUserFunds()` on Bob
  - Bob unlock the rewards (no ETH received)
