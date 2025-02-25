# BDaF 2025 Lab01 Solidity by yourself

- Deadline: March 4th before lecture
- Submission: [Link](https://docs.google.com/forms/d/e/1FAIpQLSc-iwSQLdPdPJdE5m5HtBgVW-tHVHzW7L-BDguKsGUgicillg/viewform?usp=dialog)

## Readings
  - Framework to use (choose one)
    - [Hardhat](https://hardhat.org/docs)
    - [Foundry](https://book.getfoundry.sh/)
  - Solidity Guide
    - [BDaF 2024 Solidity Intro](https://drive.google.com/file/d/1b6LD3zkHUzHJPdyjNuWwAeLA7Tprfq7v/view)
    - https://cryptozombies.io/
    - https://docs.soliditylang.org/en/latest/
 
## Pre-requisites
1. Create a repository on GitHub to host all future labs from this course
2. Share the repository with the github account `bdaf-course`, `martinetlee`, and `grace0950`

## Project Overview:

### Contract Requirement
- This contract receives ETH and emits event to record that certain address has sent it ETH for how much. 
- The events emitted should include the address and the amount received.
- There should be one specific address that can withdraw all those funds received
- no other addresses should be able to withdraw the funds stored in the contract

### Project Setup Requirement
- Project MUST use either hardhat or foundry as framework
- Tests must be present and tests the requirements listed above.
- Tests should pass.
  - TA should be able to run it via `npx hardhat test` (hardhat) or `forge test` (foundry)

