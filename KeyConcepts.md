Review of Key concepts 
===

## Why Blockchain

* Defensive Technology
    * A non-government controlled currency that allows people to switch to anytime, without censorship
        * Dystopia - wechat
        * Payment systems that are controlled centrally
    * Privacy... well it's still lacking, but that was one of the goals (anyone tells you blockchain is good because it is FULLY transparent, is not clear about this core value)
* Killer Advancement
    * Instant settlement ![Screenshot 2025-04-22 at 3.27.07 PM](https://hackmd.io/_uploads/rJPC4pVJgx.png)
    * Complex business logic beyond settlement

### Why Privacy and Censorship resistance matter

Question:
* Is the current model of privacy - "publicly private", but "privately known" good enough?

The world is more digital than ever, and centralized party can collect much more invasive information compared to 20 years ago. Information is power, and the capability of manipulating information is also power. 

WE have experienced:
* Cambridge Analytica
* Meta/Facebook Censorship scandal (recent, about Taiwan)
* Misinformation campaigns from all nation states to control each others' citizens
* Personalized Ad that are super invasive ("wait why am i seeing this ad right after I talked about XXX")

WE have NOT experienced, but has happened in the world:
* Having a cup of tea over some political view you have wrote in a private chat
* Banks denying / severly limiting withdrawals
    * South America - a person "robbed" a bank to get his own money, so that he can pay for his father's medical operation.
    * China

### Think about the end goal, not the means

Blockchain is not the end goal - tech is never the end goal. What matters is what we want to bring into the world.

* Censorship resistant & Privacy: To preserve the freedom of general humanity as the world grows into a more digital and easily centralized world.
    * Censorship resistant: to ensure power cannot be enforced directly.
    * Privacy: to maintain power against centralized entities.
* Efficiency: T-1 day was a big news for Nasdaq. Ethereum L1 is 13s settlement, L2s are typically 2s settlement.

Other goals that are not widely adopted in the blockchain and hindering its adoption:
* Fool-proof security: mechanisms that allow users to not be phished / attacked / fat fingering.
* Fund security: mechanisms that protects users funds
* Fool-proof fund storage: What should the user do when they lose their private keys / mnemonics?
* Easy of use with minimum knowledge

Note that goals are not always aligned and may need to design a system that balances them.

### Moral issue

Question: Is being illegal always a bad thing?

![Screenshot 2025-04-22 at 4.05.56 PM](https://hackmd.io/_uploads/BJVxRpV1xe.png)

https://en.wikipedia.org/wiki/Export_of_cryptography_from_the_United_States

## Incentives, incentives, incentives
Whether it be the general world trend or technology, always think about incentives. If there is no incentives, there is no persistent action. 

Blockchain technology is a great way for people to get intuitive with incentives from financial side, but soon this view can expand onto other fields and more high level things - like the moral issue above.

## General Blockchain Knowledge
* Securing the network
    * PoW & PoS
* Double Spending Attack
* Hash
    * What is hash?
    * What is Merkle Tree used for?
        * proving something is in `X` while not needing to store everything publicly.
    * What is the commit reveal scheme? 
* Why is storing / computing on blockchain costly?
* Random: is CEX crypto?


## EVM
* When something reverts in execution, everything reverts
* delegateCall
* create1 & create2
* function signature and fallback function

## Basic Security
* Not your keys, not your money
* Don't trust, verify
* Password Manager
    * Can I store my private keys in password manager?
* How to store private keys / mnemonic securely
    ![secure](https://cdn.discordapp.com/attachments/1192417632079593563/1359067162299600916/IMG_9727.jpg?ex=6808966d&is=680744ed&hm=4a7b33ebe4f0f731d3ef70abf4f6b5a81469d6f3eab7ca273099d4b023a71fbd&)

## DeFi

### Asset representation
* We can easily represent assets with ERC20, ERC721, ERC1155 (not taught)

### DEX
* Classification
    * AMM model
        * Uniswap / Balancer / Curve
        * Problem for LPs - impermanent loss
    * Orderbook model
        * not gas efficient on L1 blockchains
        * having a comeback on L2s
* Liquidity Depth
    * How to create a 1 Billion FDV token NOW - the illusion of MarketCap and Fully Diluted Valuation
    * Liquidity Depth is what matters - how to check them?
* Liquidity Efficiency was the innovation on AMMs
    * Difference between Uniswap & Curve / UniswapV3


### Oracle
Blockchain does not know anything beyond the chain. So how do we give them information like stock prices, ETH prices, etc?

* we have not talked about how to secure them yet

### Stablecoin
* Centralized - USDC / USDT
    * What are the systemic risks of the protocol?
* Decentralized - MakerDAO
    * What are the systemic risks of the protocol?
* Liquidation
    
### Lending Protocol
* Collateralization Factor
* Utilization rate
* Old-school lending protocols: Compound / Aave
    * What are the systemic risks?
* Flashloan

### Yield Aggregator
* What do they do, in simple manner?
    * get yield, convert back to principal, and re-invest automatically for all users at once.
* Compounding: APR to APY
* Opportunity size matters

### Bridge 
* Atomic Swap
    * Hashed TimeLocked Contract (HTLC)
* Lock and Mint Bridge structure
* Burn and Mint Bridge structure
* Other bridges
    * Message passing bridge

### Random
* What is the effect of token issuance? PoW/PoS or other mechanism?
* Why does two opportunities have different yields?
    * Let's say, two lending protocols

## L2
* Why do we need L2?
* Mechanism 
    * Optimistic
    * Zero-Knowledge
* General Structure of L2
* Based roll-up?
* Data Availability Layer?

## MEV
* sandwich attacks
* arbitrage
* any money making opportunities on the blockchain


## Security Audit & Mindset
### Attacks
* "Flashloan attacks"

### Audits
* Impossible to get "bug-free"
* Consider as expert review to review code
* Should you apply whatever the changes the auditors suggested?
* Do all the best practices - code readability, tests, etc
    * reduce cost
    * improve security

### Security Mindset
* Always try to misbehave and see who is damaged
* Always think about incentives - how can a party gain money?
    * Steal directly
    * Ransom
* Always consider human error
* Common Pitfalls
    * integration with other protocols
    * decimals / units
    * borders
    * byte packaging


