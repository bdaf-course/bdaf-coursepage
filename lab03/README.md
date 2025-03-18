# BDaF 2025 Lab03 Warming up for the Hackathon

- Deadline: March 25th before the lecture (1 week deadline!)
- Submission: 

## Part 1: A contract that deploys contracts, with create2

We will practice basic Factory pattern with create2, getting a taste of predetermined address

### Project Requirement
* write a smart contract that can withdraw any ERC20 tokens from it by its owner
* write a factory contract that can deploy the above contract using Create2, you can use [OpenZeppelin's Create2 library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol)
    - note that we should be able to specify the address of the owner, and the owner address should be used to determine the address of the smart contract that will be deployed
* On-chain actions (4 tx hashes to be recorded)
    1. Deploy the factory on Zircuit
    2. Send tokens to a pre-computed address
    3. Deploy the smart contract to the pre-computed address
    4. Withdraw the tokens
* Note that action 3 must come after action 2. We will check the time.

- To save time, no tests are required for this project. 

## Part 2: Warming up for the Hackathon
Pick projects on the list and build pocs with their techstack, with frontend
- https://ethglobal.com/events/taipei/prizes

For this project, you can team up with other class members

### Ideas to build

#### Useless fun stuff
- Detects user wallet actions and generate image for that. Imagine you feed your pet with wallet actions. Underlying this can be a reputation protocol - allowing users to link multiple wallets together.

#### UX
- How can I send tokens to someone who doesn't have a wallet, but only email?

#### Tooling
- Tooling that given a set of deployer addresses, crawls the smart contract it deployed and draw the graph of the relationship between smart contracts and addresses
- Tooling that given an address, it finds all relevant addresses that the address has interacted with and try determine these addresses automatically. (may consider use AI here)
- Given an address, create a google sheet filled with all relevant transactions on different chains, specifically token transfers or any value transfer transactions. Try annotate those transactions 

#### AI related ideas
- Abstract the wallet away from the user, allow user use AI to send/swap tokens through different chains 
- [MCP](https://www.anthropic.com/news/model-context-protocol) for Crypto use cases 
    - MCP for datasets (Nodit / Alchemy / Tenderly?)
    - MCP for wallet actions (create wallet / transfer tokens / bridge / etc)
- An AI that determines the reputation of an address, given some description of the definition of reputation
- RPC endpoint that detects user transaction and detects whether it is being phished / scammed. Can use AI for detection and build up the blacklist. 
- Transaction Explainer - given a transaction hash, expalin what happens in the transaction
- AI that helps deploy contract and frontend on different chains.
- DAO voting with AI bars - before you vote, you must demonstrate knowledge on the topic. You get different multipliers on your voting power depending on how well you've done.

Nodit: multichain web3 infrastructure 
DEX Aggregator: 1inch
L1 & L2s: World, Rootstock, Flow, Arbitrum, Polygon, Zircuit, ENS

### Project Requirement

- Have a frontend that can interact with Metamask / Wallets
- Clear integration of the application with a non-L2/L1 Project in an interesting way(could be outside of the list, like ENS, MCP)
- If you have great ideas that doesn't require frontend, can discuss and get approval

### Deliverables
- Demo'able application
