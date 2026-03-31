# Lending Protocols — Supplementary Material

CSIC30161 Blockchain Development and Fintech | Martinet Lee

---

## Part I: Deeper Dive into Lending Protocol Mechanics

---

### 1. Interest Rate Models

In the slides we saw that each lending pool has an `InterestRate` contract. But how does it actually decide the rate?

#### Utilization Rate

The core input is **utilization** — what percentage of the deposited pool is currently borrowed.

```
Utilization = Total Borrowed / Total Supplied
```

If a pool has 100 USDC supplied and 80 USDC borrowed, utilization = 80%.

#### The Kink Model (Compound / Aave)

Most lending protocols use a **piecewise linear** interest rate curve with a "kink" — a sharp inflection point that discourages the pool from being fully utilized.

```
                Borrow Rate
                    │
                    │                        /
                    │                       /
                    │                      /  ← steep after kink
                    │                     /
                    │                ____/
                    │           ___/
                    │      ___/  ← gradual before kink
                    │ ____/
                    │/
                    └──────────────────────── Utilization
                    0%       80%        100%
                              ↑
                            kink
```

**Below the kink (~0-80% utilization):** Rates rise slowly. Borrowing is cheap, depositing earns modest yield.

**Above the kink (~80-100%):** Rates rise steeply. This does two things:
- Incentivizes borrowers to repay (expensive to hold the loan)
- Incentivizes new depositors to supply (high yield)

The kink exists because **100% utilization is dangerous** — depositors cannot withdraw if every token is lent out. The steep rate above the kink is a market-based mechanism to keep a liquidity buffer.

#### Typical Parameters (Aave V3 USDC example)

| Parameter | Value |
|---|---|
| Base rate | 0% |
| Slope 1 (below kink) | 3.5% |
| Slope 2 (above kink) | 60% |
| Optimal utilization (kink) | 80% |

At 50% utilization: borrow rate ~ 2.2%
At 80% utilization: borrow rate ~ 3.5%
At 90% utilization: borrow rate ~ 33.5%

#### Supply Rate Derivation

Depositors (suppliers) earn interest from what borrowers pay, minus a protocol fee (reserve factor):

```
Supply Rate = Borrow Rate × Utilization × (1 - Reserve Factor)
```

If borrow rate = 5%, utilization = 80%, reserve factor = 10%:
```
Supply Rate = 5% × 0.8 × 0.9 = 3.6%
```

This is why the spread between supply and borrow rates exists — analogous to the bank's spread in the slides, but set by math rather than a bank's decision.

#### Adaptive Rate Models

Newer protocols adjust the curve itself over time:
- **Aave V3** adjusts the optimal utilization point based on market conditions
- **Morpho Blue** uses a market-driven approach — rates are determined by peer-to-peer matching, not a curve

**Discussion question:** What happens if the kink is set too low (e.g., 50%)? What if it's set too high (e.g., 95%)?

---

### 2. Liquidation Mechanism Evolution

The slides covered three DeFi liquidation types: fixed discount, auction, and changing discount. Let's go deeper into how these work and what's new.

#### Fixed Discount Liquidation (Compound V2, Aave V2)

From the slides, we saw Compound's `liquidateBorrowFresh`. The core idea:

1. Borrower's health factor drops below 1 (collateral value < required threshold)
2. Anyone can call `liquidate`, repaying some of the borrower's debt
3. In return, the liquidator receives collateral at a **fixed discount** (e.g., 5-10%)

```
Liquidator pays: 100 USDC of debt
Liquidator receives: $105 worth of ETH collateral (5% bonus)
```

**Problems with fixed discount:**
- If the discount is too small → no one bothers to liquidate → bad debt
- If the discount is too large → borrowers lose too much value → punitive
- During market crashes, **many positions become liquidatable simultaneously**, causing cascading liquidations and gas wars

#### Close Factor

Compound V2 introduced a **close factor** — the liquidator can only repay a portion (e.g., 50%) of the debt per transaction. This prevents a single liquidator from seizing all collateral and gives the borrower a chance to recover.

#### Aave V3: Efficiency Mode (e-Mode)

Aave V3 recognized that not all collateral pairs have the same risk. **E-mode** groups correlated assets and allows higher LTV ratios:

| Mode | Example Pair | Max LTV | Liquidation Threshold |
|---|---|---|---|
| Normal | ETH / USDC | 80% | 82.5% |
| e-Mode | stETH / ETH | 93% | 95% |
| e-Mode | USDC / DAI | 97% | 97.5% |

Since stETH and ETH are highly correlated, the chance of the collateral dropping below the borrow value is much lower, so the protocol can safely allow higher leverage.

#### Soft Liquidation: Curve's LLAMMA

The most significant liquidation innovation is Curve's **LLAMMA** (Lending-Liquidating AMM Algorithm), used in crvUSD:

Instead of a sudden liquidation event, LLAMMA **gradually converts collateral into the borrowed asset** as the price drops, and **converts back** if the price recovers.

```
Price falling:
  ETH collateral → gradually sold for crvUSD → debt reduced smoothly

Price recovering:
  crvUSD → gradually converted back to ETH → collateral restored
```

This works by placing the user's collateral into a specialized AMM (similar to a Uniswap pool) within specific price bands. As the market moves through those bands, the AMM automatically rebalances.

**Advantages:**
- No sudden, punitive liquidation event
- Borrower retains more value during volatile but recovering markets
- Less MEV extraction by liquidator bots

**Tradeoffs:**
- "Soft liquidation losses" — each conversion through the AMM incurs a small loss
- If price drops fast and doesn't recover, the cumulative losses can exceed a traditional liquidation penalty

#### Bad Debt: When Liquidation Fails

This connects to the slides' "when does a lending protocol fail" section. Bad debt occurs when:

1. Collateral value drops **below** debt value before liquidation happens
2. No liquidator is willing to act (gas costs > profit, extreme congestion)
3. The collateral is illiquid — can't be sold at oracle price

When bad debt exists, the protocol must decide:
- **Socialize the loss** — all depositors share the loss proportionally (Aave's approach via the Safety Module)
- **Protocol treasury absorbs it** — if reserves are sufficient
- **It just... sits there** — some protocols have had unresolved bad debt for months

**Real example:** In Nov 2022, a single wallet exploited Aave V2 on Ethereum, creating ~$1.6M in CRV bad debt by manipulating the CRV market.

---

### 3. Oracle Risk — Deeper Treatment

The slides mentioned: "What if the price was incorrect?" Let's unpack why this is one of the most critical attack surfaces in DeFi lending.

#### Why Oracles Matter

Every lending protocol decision depends on price:
- Can this user borrow? → Requires collateral valuation
- Should this user be liquidated? → Requires real-time price comparison
- How much collateral does the liquidator receive? → Requires price calculation

If the oracle reports a wrong price, **the entire protocol operates on false assumptions**.

#### Types of Price Oracles

**1. Centralized Feeds (Chainlink)**
- Network of independent node operators fetch prices from exchanges
- Aggregated on-chain with deviation thresholds (updates when price moves >0.5%)
- Most widely used — Aave, Compound V3 rely on Chainlink
- Risk: oracle staleness (price hasn't updated during fast crash), centralization trust

**2. On-Chain TWAP (Time-Weighted Average Price)**
- Computed from DEX trading data (e.g., Uniswap V3 TWAP)
- Fully decentralized — no external trust
- Risk: **manipulable** if the DEX pool has low liquidity; attacker can move the price with a large trade

**3. Pyth Network**
- Pull-based oracle — price data is published off-chain and pulled on-chain when needed
- Sub-second latency, used heavily on Solana and increasingly on EVM chains
- Risk: relies on data providers (market makers, exchanges)

#### Oracle Manipulation Attacks

This is the concrete mechanism behind the "make collateral value very high temporarily" attack from the slides:

```
Attack flow:
1. Flash loan a large amount of tokens
2. Use them to manipulate a DEX pool price (buy massively → price spikes)
3. The oracle reads the manipulated price
4. Deposit the inflated-value token as collateral
5. Borrow maximum amount against the fake price
6. Price returns to normal → collateral is now worth less than debt
7. Walk away with borrowed funds; protocol holds bad debt
```

**Defenses:**
- **TWAP over multiple blocks** — harder to sustain a fake price over time, but slower
- **Multiple oracle sources** — Chainlink + TWAP fallback
- **Borrow/supply caps** — limits the damage from any single asset (see next section)
- **Listing policy** — only list assets with deep, manipulation-resistant liquidity

**Discussion question:** The slides mentioned "listing policy matters" for collateral risk. Why is a low-liquidity token more dangerous as collateral than a high-liquidity one, even if its current price is stable?

---

### 4. Supply-Side Mechanics and Risk Controls

The slides showed depositors earning 0.1% interest. In practice, modern lending protocols have several mechanisms controlling the supply and borrow side.

#### Supply Caps and Borrow Caps

Introduced in Aave V3 and Compound V3, these are hard limits on how much of a given asset can be supplied or borrowed.

```
Example:
  wstETH supply cap: 200,000 wstETH
  USDC borrow cap: 50,000,000 USDC
```

**Why caps matter:**
- Limits protocol exposure to any single asset
- Prevents oracle manipulation attacks from being profitable at scale
- Controls concentration risk — even if ETH is "safe," having 90% of the protocol in one asset is risky

#### Reserve Factor

A percentage of all interest paid by borrowers goes to the protocol treasury rather than depositors:

```
Borrower pays 5% interest
  → 4.5% goes to depositors
  → 0.5% goes to protocol reserves (10% reserve factor)
```

Reserves serve as a first-line buffer against bad debt.

#### Rehypothecation Risk

In some protocols (Compound V2, Aave V2), when you deposit ETH as collateral, that ETH is available for other users to borrow. Your collateral is being lent out.

**What could go wrong:**
- If many borrowers default simultaneously, the collateral you deposited might not be there for you to withdraw
- This is analogous to a traditional bank run

**Compound V3 (Comet) addressed this** by separating collateral from lending. Collateral assets in Compound V3 are **not** lent out — only the base asset (e.g., USDC) is borrowable.

#### Withdrawal Liquidity

Even without bad debt, depositors can get stuck if utilization is at or near 100%. There's simply no idle liquidity in the pool to withdraw. The steep interest rate above the kink is designed to prevent this, but during extreme market events it can still happen temporarily.

---

### 5. Governance and Risk Management

The slides mentioned the role of "Admin" (replacing "Bank"). Let's look at how governance actually works.

#### Parameter Governance

A lending protocol has dozens of tunable parameters per market:
- Collateral factor / LTV ratio
- Liquidation threshold and bonus
- Interest rate model parameters (slopes, kink)
- Supply and borrow caps
- Reserve factor
- Oracle source

These are typically controlled by **governance token holders** (e.g., AAVE, COMP) through on-chain voting.

#### The Problem with Governance

Governance is slow — a typical proposal takes 7-14 days from proposal to execution. But markets move fast.

**Risk scenario:** A collateral token's liquidity drops 80% overnight. The correct response is to lower its LTV immediately. But governance takes a week to pass the change.

#### Risk Management Providers

To solve the speed problem, major protocols outsource parameter recommendations to specialized firms:

- **Gauntlet** — runs agent-based simulations of market conditions to recommend optimal parameters
- **Chaos Labs** — similar simulation-based approach, provides real-time risk dashboards

These firms propose parameter changes, and governance approves (or rejects) them. It's a hybrid of expert analysis and decentralized approval.

#### Emergency Mechanisms

For critical situations, protocols have faster paths:

- **Guardian/Emergency Admin** — a multisig (e.g., 5-of-9) that can pause the protocol or freeze a market instantly without waiting for governance
- **Automatic pause triggers** — some protocols can halt markets if oracle prices deviate beyond a threshold

**Tension:** Emergency powers are centralized by design. More emergency power = faster response but less decentralization. Every protocol makes this tradeoff differently.

---

## Part II: Newer Types of Lending

---

### 6. Isolated and Modular Lending Markets

#### The Problem with Shared Pools

In Compound V2 and Aave V2, all assets share one risk pool. If you deposit USDC, your funds can be affected by a bad collateral listing (say, a low-liquidity governance token) — even though you never wanted exposure to that asset.

The March 2023 CRV bad debt event on Aave showed this in practice: a single exploited collateral affected all USDC depositors.

#### The Shift: Isolated Markets

The current generation of lending protocols isolates risk at the market level.

---

#### Morpho Blue

Morpho Blue (launched 2024) takes the most radical approach to modularity.

**Core design:** Morpho Blue is a **single, immutable, minimal smart contract** (~650 lines of Solidity). It has no governance, no upgradability, no oracles built in. It only provides the primitive: create a lending market.

Each market is defined by exactly 5 parameters:
```
Market = (collateral token, loan token, oracle, IRM, LLTV)
```
- **Collateral token** — what the borrower provides
- **Loan token** — what the borrower receives
- **Oracle** — the price feed used
- **IRM** — the interest rate model contract
- **LLTV** — liquidation loan-to-value ratio

**Anyone can create a market** with any combination of these 5 parameters. There is no listing governance, no shared risk.

**Key properties:**
- Each market is completely isolated — bad debt in Market A cannot affect Market B
- No governance risk — the contract is immutable
- No admin keys — no one can change parameters after market creation
- Extremely gas-efficient due to minimal contract size

**The tradeoff:** Morpho Blue by itself is a raw primitive. Depositors would need to manually evaluate and choose between hundreds of markets. This is where **Morpho Vaults** (formerly MetaMorpho) come in — curated vault strategies that allocate across multiple Morpho Blue markets, run by risk managers. Think of it as:

```
Morpho Blue = the engine (minimal, trustless)
Morpho Vaults = the car (curated, opinionated, managed)
```

A depositor who wants simple "deposit USDC, earn yield" uses a vault. A sophisticated user or institution can go directly to Morpho Blue and pick exact risk parameters.

**Impact on the market:** Morpho has grown to one of the largest lending protocols by TVL, demonstrating that the modular approach has strong product-market fit. Its success has pushed Aave to announce Aave V4 with similar modular concepts.

---

#### Euler v2

Euler v2 (launched 2024-2025) takes a different path to modularity.

**Core concept: Euler Vault Kit (EVK)**

Euler v2 is a **vault-based system** where each vault is an independent lending market. But unlike Morpho Blue's single-contract approach, Euler provides a **framework** for building vaults with composable features.

```
Euler V2 Architecture:
┌─────────────────────────────────┐
│  Ethereum Vault Connector (EVC) │  ← cross-vault account management
├────────┬────────┬───────────────┤
│ Vault A│ Vault B│   Vault C     │  ← each is an isolated market
│ ETH/   │ wstETH/│   USDC/       │
│ USDC   │ USDC   │   DAI         │
└────────┴────────┴───────────────┘
```

**The Ethereum Vault Connector (EVC)** is the key innovation. It's a layer that sits beneath all vaults and enables:

- **Sub-accounts** — a single address can have up to 256 sub-accounts, each with its own positions
- **Cross-vault operations** — collateral in Vault A can back a borrow in Vault B (if the vault creator allows it)
- **Operators** — delegate position management to other contracts (enables more complex strategies)
- **Gasless transactions** — batch multiple vault operations in one transaction via permits

**Key difference from Morpho Blue:**
- Morpho Blue: one contract, one market definition, fully immutable
- Euler v2: a framework for building vault markets with configurable features, governed by vault creators

Euler v2 allows **vault creators to set their own governance** — some vaults might be governed, others immutable. Each vault creator decides:
- Which collaterals to accept
- Which oracle to use
- Interest rate model
- Liquidation parameters
- Whether the vault is upgradable

**Nested vaults:** An Euler vault that accepts deposits can itself be used as collateral in another vault. This enables composable, layered lending structures — powerful but introduces dependency chains that require careful risk analysis.

---

#### Comparison Table

| Feature | Compound V2 / Aave V2 | Morpho Blue | Euler v2 |
|---|---|---|---|
| Risk isolation | Shared pool | Per-market | Per-vault |
| Market creation | Governance vote | Permissionless | Permissionless |
| Immutability | Upgradable | Fully immutable | Vault-creator decides |
| Governance | Token voting | None | Per-vault |
| Oracle choice | Protocol-wide | Per-market | Per-vault |
| Cross-collateral | Yes (shared pool) | No | Optional (via EVC) |
| Curation layer | Not needed | Morpho Vaults | Aggregator vaults |
| Gas efficiency | Medium | Very high | Medium |

---

### 7. Undercollateralized and Credit-Based Lending

#### The Limitation of Overcollateralized Lending

Everything in the slides assumes overcollateralization — you must deposit more than you borrow. This means DeFi lending is primarily used for:
- Leveraged trading (deposit ETH, borrow USDC, buy more ETH)
- Accessing liquidity without selling (tax or strategic reasons)

But it does **not** serve the most common real-world use case: borrowing money you don't already have (mortgages, business loans, student loans).

#### Credit Delegation (Aave)

Aave introduced **credit delegation** — a depositor can authorize a specific borrower to borrow against the depositor's collateral without the borrower providing their own.

```
Alice deposits 100 ETH into Aave
Alice delegates credit to Bob (off-chain legal agreement)
Bob borrows 50,000 USDC — backed by Alice's ETH
If Bob doesn't repay → Alice's ETH gets liquidated
```

The risk is managed **off-chain** through legal agreements. The smart contract only enforces the delegation permission, not the credit assessment.

#### Institutional Lending Protocols

A class of protocols emerged specifically for undercollateralized institutional lending:

**Maple Finance**
- Pool delegates (experienced credit analysts) run lending pools
- They assess institutional borrowers (trading firms, market makers) and approve loans
- Depositors choose which pool delegate to trust
- Collateral requirements are lower or zero — relying on borrower reputation + legal agreements
- After several defaults in 2022 (FTX/Alameda collapse), Maple pivoted toward more secured structures

**Goldfinch**
- Targets real-world borrowers in emerging markets (e.g., fintech lenders in Africa, Southeast Asia)
- Two-tier structure: "Backers" do due diligence on borrowers and take first-loss risk; "Senior Pool" depositors take lower risk
- Loans are backed by real-world assets and legal agreements, not on-chain collateral

**Clearpool**
- Permissionless institutional credit marketplace
- Each institutional borrower has its own pool with a market-determined interest rate
- Borrower's creditworthiness affects the rate — higher risk = higher rate demanded by market

#### Real-World Asset (RWA) Collateral

The bridge between DeFi and traditional lending: using tokenized real-world assets as collateral.

- **Tokenized US Treasuries** (e.g., Ondo Finance's OUSG, Backed Finance's bIB01) as collateral on lending protocols
- **Tokenized real estate** or receivables as collateral
- **MakerDAO** (now Sky) was a pioneer — accepting RWA collateral for DAI loans

This is still early and introduces legal/regulatory complexity: what happens when a smart contract needs to foreclose on a real building?

---

### 8. Cross-Chain Lending

#### The Problem

DeFi liquidity is fragmented across chains. If you have ETH on Ethereum but want to borrow USDC on Arbitrum, traditionally you'd need to:
1. Bridge ETH to Arbitrum
2. Deposit into a lending protocol on Arbitrum
3. Borrow USDC

Each step has cost, latency, and bridge risk.

#### Aave V3 Portal

Aave V3 introduced **Portal** — a mechanism for cross-chain lending:

```
1. User deposits ETH on Ethereum (Aave V3)
2. Aave mints "bridged" aTokens on Arbitrum
3. User borrows USDC on Arbitrum against their Ethereum collateral
```

Under the hood, Portal relies on whitelisted bridge protocols to pass messages between chains. The bridged aTokens are backed by a delayed bridging of the actual underlying assets.

**Trust assumption:** You're trusting the bridge protocol (e.g., Hashflow, Stargate) to correctly relay the state. Bridge exploits have caused billions in losses across DeFi, so this is a meaningful risk addition.

#### Native Cross-Chain Protocols

Some newer protocols are built cross-chain from the ground up:
- Borrow on one chain, collateral on another, without manual bridging
- Use messaging protocols (LayerZero, Hyperlane, Wormhole) for state synchronization
- **Radiant Capital** was an early attempt (built on LayerZero), though it suffered a private key compromise in 2024

#### The Core Challenge

Cross-chain lending introduces a fundamental problem: **atomic liquidation is impossible across chains**.

If your collateral is on Chain A and your debt is on Chain B:
- Chain A doesn't know the current debt value on Chain B in real-time
- A liquidator needs to coordinate actions on both chains
- Message delays between chains create windows where the position is "stale"

This is an active area of research with no clean solution yet. Current approaches trade off between speed, security, and decentralization.

---

## Further Reading

- Compound V3 (Comet) documentation — the transition from shared to isolated lending
- Morpho Blue whitepaper — minimal, immutable lending primitive design
- Euler v2 documentation — vault-based modular lending with EVC
- LLAMMA whitepaper (Curve) — soft liquidation mechanism
- Gauntlet risk reports — quantitative risk management methodology
