# Smart Contract Security Audits — Supplementary Material

CSIC30161 Blockchain Development and Fintech | Martinet Lee

> Companion to the lecture deck *"So what is an audit anyway?"*. The slides set up the conceptual frame — what an audit *is* (vs accounting), why it is fundamentally time-limited, the auditor's "intention vs implementation" thought process, the typical engagement workflow, and defense-in-depth. This document goes deeper into how that frame actually plays out in 2026, with concrete firms, tools, dollar amounts, and incidents.

---

## Part I: How the Audit Layer Has Changed Since the Slides

---

### 1. The defense-in-depth pipeline is now an explicit market

The slide deck described five layers: best practices → automated scanning → whiteglove audit → monitoring → insurance. In 2026, **every layer has 3–5 commercial vendors competing on it**. An audit is no longer the whole product; it is one stage in a pipeline.

```
        Best Practices                  Solidity style guide, OZ libraries
              │
              ▼
    Automated Scanning  (CI)          Slither / Aderyn / Wake / Olympix
              │
              ▼
       Audit Layer                    Trad firms / Contests / Boutiques
              │
              ▼
  Formal Verification  (selective)    Certora / Kontrol / Halmos
              │
              ▼
        Monitoring                    Forta / Hypernative / Phalcon / Hexagate
              │
              ▼
     Incident Response                SEAL 911 / war-rooms / whitehat
              │
              ▼
        Insurance                     Nexus / Sherlock / Chainproof / Neptune
```

Three numbers anchor why this matters:

- **2024 stolen funds:** ~$2.2B across reported on-chain hacks (Chainalysis). For the first time, **private-key compromise of centralized services overtook smart-contract bugs** as the leading loss vector.
- **2025 stolen funds:** ~$3.4B, dominated by the Bybit incident alone.
- **2025 Q4 Ethereum monthly contract deployments:** ~8.7M (Olympix telemetry), up from ~6M in Q2 2021.

The audit surface area is growing far faster than auditor headcount. Defense-in-depth is not a nice-to-have; it is the only way the math works.

---

### 2. Audit firm landscape, 2024–2026

The slide deck mentions Quantstamp specifically; in practice the market segments into three tiers.

#### Tier A — full-stack consultancies

| Firm | Focus |
|---|---|
| **Trail of Bits** (NYC) | Cryptography, zkVMs, Rust/Solana, infra. Authors of Slither, Echidna, Medusa. |
| **OpenZeppelin** (global) | DeFi blue-chips (Compound, Aave, ENS, Optimism). Maintainer of OZ Solidity libraries. |
| **ConsenSys Diligence** | Uniswap, MakerDAO, 0x. Run MythX. |
| **ChainSecurity** (ETH Zürich) | Mathematical/economic-mechanism review. Disclosed the TSTORE low-gas reentrancy class in 2024. |
| **Sigma Prime** (Sydney) | Lighthouse consensus client; deep Ethereum core. |
| **Quantstamp** (SF) | 1,100+ projects, ~$200B+ protected value. Multi-chain. QSP continuous-audit model. |
| **Halborn** (Miami) | Offensive-security flavor: red-teaming, social engineering, custody/wallet/infra. |
| **Runtime Verification** | Academic FV roots (K-framework). Authors of KEVM and Kontrol. |
| **Dedaub** (Athens) | Decompilation/static analysis. Operates the public Dedaub Decompiler. |

#### Tier B — boutiques and rising firms

- **Spearbit / Cantina** — Spearbit's "guild" of independent senior researchers now operates inside Cantina (cantina.xyz). Spearbit Reviews require a minimum of two Lead Security Researchers; "Cantina Reviews" tier waives that minimum for budget flexibility.
- **Zellic** — Solana/Move expertise, cryptographic review. Acquired CodeHawks in 2024.
- **Ackee Blockchain** (Prague) — developers of the Wake framework; auditors of Lido, Safe, Axelar.
- **Cyfrin** (UK) — runs Aderyn and the CodeHawks contest platform; education arm Cyfrin Updraft.
- **Solana specialists** — OtterSec ($5B+ TVL protected, also Sui/Aptos), Neodyme (Mango, deBridge, Solana Stake Pool). Both engaged on the May 2 2025 Solana ZK ElGamal Proof program patch.

#### Tier C — contest / marketplace platforms

Covered in §3.

#### A defensible pricing rule for students

> Budget **~$3–$10 per LOC per auditor-week, with a 2-auditor minimum, plus a fix-review week**.

This will be wrong on either tail (a 200 LOC AMM hook is harder per-LOC than a 5000 LOC ERC20 wrapper) but is a sane default for budgeting an early-stage protocol. Cross-reference: [Sherlock's 2026 market reference](https://sherlock.xyz/post/smart-contract-audit-pricing-a-market-reference-for-2026).

---

### 3. Contest / crowdsourced audit platforms

The slide deck shows the Code4rena leaderboard. Worth understanding *why* this model exists alongside traditional firm engagements.

#### Code4rena (C4)

Largest pool — ~10,000+ registered "Wardens." `cmichel` was the first individual to cross $1M lifetime contest earnings. In 2025 C4 dropped its platform fee to **0%** for sponsors and shifted top-tier work into invite-only "Zenith" private contests. Award split: 80% high/medium pool, plus separate judging and gas-optimization pools.

#### Sherlock

Hybrid contest + insurance protocol. Pre-contest a **Lead Security Watson (LSW)** is selected and earns a fixed retainer (originally $25k/week, now capped ≤$12.5k/week). Watsons must clear a 20% issue-ratio threshold across recent contests to earn USDC payouts. **Sherlock stakes its own capital against the audit through its coverage protocol** — if a covered exploit happens, the staking pool pays. The mechanism literally aligns auditor incentives with protocol safety.

#### Cantina (incl. Spearbit guild)

Tends to draw the "infrastructure / massive codebase" mandates (L1s, L2s, 100k+ nLOC). Top performers regularly clear $100k from a single contest. Cantina also offers traditional firm-style "Cantina Managed" reviews alongside contests.

#### CodeHawks (Zellic-acquired)

Beginner-friendly; keeps a "First Flights" track for novice auditors. Acquisition by Zellic (2024) signals consolidation.

#### Immunefi

Bug-bounty marketplace, **not** a contest platform — protocols only pay out for found-in-production vulnerabilities. The standard severity reference (see §6) is theirs.

#### Pros / cons of the contest model

**Pros:** unbounded auditor count, asymmetric incentives (highest-impact finding takes most of the prize), depth on novel bug classes, public learning artifact (judging repos are a goldmine for students).

**Cons:** time-boxed (often 5–14 days), no guaranteed coverage of any specific area, sponsors must triage huge issue volumes, judges can disagree about severity ("judging drama" is a recurring meme).

**Discussion question:** A protocol can spend $200k on a Trail of Bits review *or* $200k as a contest pool. Which buys more security, and under what conditions does the answer flip?

---

### 4. The 2026 auditor toolchain

The slides hint at "different sets of tooling." The practical 2026 stack:

#### Static analyzers

| Tool | Stack | Notes |
|---|---|---|
| **Slither** | Trail of Bits, Python | 93+ detectors; the canonical CI tool. |
| **Aderyn** | Cyfrin, Rust | Newer; AST-traversal in Rust, very fast, plays nicely with Foundry. |
| **Wake** | Ackee, Python | Static analysis + fuzzer + LSP + VS Code extension. Used internally by Ackee on Lido/Safe/Axelar. |
| **Olympix** | commercial | Static + mutation testing + fuzzing + AI. Vendor claims 75% detection vs ~15% legacy (treat as marketing). |
| **Mythril / MythX** | ConsenSys | Symbolic-execution-backed; lower velocity than Slither. |

#### Fuzzers

- **Echidna** (Trail of Bits, Haskell) — historical standard.
- **Medusa** (Trail of Bits, Go) — released as priority Feb 2025: Geth-based, parallel, faster. Trail of Bits has signaled Echidna is in maintenance mode. ([blog post](https://blog.trailofbits.com/2025/02/14/unleashing-medusa-fast-and-scalable-smart-contract-fuzzing/))
- **Foundry invariants** — `forge test --match-test invariant_*`; native Solidity, low friction. Default expectation in modern audit reports.

#### Symbolic execution

- **Halmos** (a16z) — Foundry frontend symbolic tester.
- **hevm** (DappHub origin) — pure EVM symbolic engine; performs well on shared SMT benchmarks with Halmos and KEVM.
- **Manticore** (Trail of Bits) — broader (binaries + EVM), low velocity but useful for academic problems.

#### Decompilers (incident triage)

- **Heimdall-rs** — open-source EVM bytecode toolkit.
- **Dedaub Decompiler** — continuously indexes millions of contracts; standard tool for unverified-contract triage during incident response.

#### Recommended sequence for students auditing their own code

```
1. forge build && forge test                  # baseline correctness
2. forge test --match-test invariant_*        # invariant fuzzing
3. slither . && aderyn .                      # static, two analyzers
4. medusa fuzz                                # stateful coverage
5. halmos OR kontrol                          # symbolic safety props
6. (optional) targeted Certora rules
```

This sequence catches roughly the same bugs that an early-tier audit would catch, *before* you pay for an audit. Per the slide deck's "Reducing your audit cost" section, this directly saves auditor-hours spent on routine findings.

---

### 5. Formal verification — the actual state in 2026

The slide deck notes the Schneier quote and lists FV's challenges (complexity, composability, bugs in the verifier, configuration error). All still true. But the picture has matured:

#### What changed

**Certora Prover open-sourced February 24, 2025.** Over 70,000 verification rules now exist publicly; CVL (Certora Verification Language) is a Solidity-flavored DSL for stating safety properties.

Certora reports having helped find/prevent 100+ safety-critical bugs and ~20 solvency bugs across Aave, Balancer, Benqi, Compound, MakerDAO, OpenZeppelin, Sushi, Lido, EigenLayer, Ether.fi, Silo, Safe, Morpho. Notable real findings:

- **Long-standing DAI rate equation bug** present since 2018 in MakerDAO's Pot contract (`drip`).
- **SushiSwap Trident** liquidity-drain vulnerability.
- **PRBMath** rounding issues that risked LP losses.
- **Aave V3 RepayWithATokens** missing health-factor check (could withdraw collateral free).

#### Where FV is now de facto mandatory

- **Aave** — every governance-approved core change ships with Certora rules.
- **Compound** — Certora maintains a continuous FV proposal.
- **MakerDAO / Sky** — DSS modules verified with K + Certora.
- **Optimism, Arbitrum, zkSync** — bridge code uses K/KEVM-based proofs.

#### What FV doesn't catch (still)

1. **Spec bugs.** "The prover proves only what you ask." If your rule doesn't mention the health factor, it won't notice the health-factor bug.
2. **Off-chain assumptions.** Oracle freshness, MEV-induced ordering, governance coercion.
3. **Compiler bugs.** Curve July 2023 (covered in §9). Vyper 0.2.15/0.2.16/0.3.0 mis-implemented `@nonreentrant`. Source-level FV alone *would not* have caught it.
4. **Economic / game-theoretic invariants** that don't fit as state predicates (e.g., weighted-AMM behavior under coordinated MEV).

#### K-framework specifics

**KEVM** is the executable formal semantics of EVM in K. **Kontrol** (Runtime Verification) bridges KEVM and Foundry: Foundry tests can be symbolically executed without writing K specs directly. K 7.0 (2024) broadened the framework; the stack also includes Kasmer (Wasm) and Komet (Soroban). For Cairo / StarkNet, recent integrations with **Lean** provide soundness arguments for circuit-related code paths.

**Discussion question:** The Curve compiler bug breaks the assumption that "verifying the source proves the deployed bytecode." How would you adjust your audit workflow to compensate?

---

### 6. AI in auditing — what it does, what it doesn't

The slide deck deliberately avoids naming AI. In 2026, ignoring AI in auditing is a teaching gap.

#### What AI is good at today

- **Triage and code understanding.** GPT-4/5, Claude Opus, Codex agents, Cursor agents are routinely used for fast onboarding to a new codebase, generating call graphs, drafting natspec, and producing first-pass finding hypotheses.
- **Test generation.** Foundry test scaffolding from natural-language invariants is a strong AI use case.
- **Pattern recognition** for known classes (reentrancy, missing access control). Olympix's CI integration *claims* 71% of H1 2025 hacks could have been caught by their detection methods (vendor figure — verify before quoting).
- **OpenAI's EVMbench (2025)** measured AI agents on bug-detection tasks; Claude Opus 4.6 via Claude Code scored 45.6% on Detect, the highest reported figure.

#### Commercial offerings worth knowing

| Product | Owner | Positioning |
|---|---|---|
| **Olympix** | independent | CI-native: static + mutation + fuzzing + AI invariant suggestions |
| **Quantstamp Hyper** | Quantstamp | AI-assisted continuous review layered on QSP retainers |
| **Sherlock AI** (beta, Sep 2025) | Sherlock | trained on Sherlock's contest dataset; severity-ranks findings |
| **Wake Arena** | Ackee | multi-step reasoning over 87 private detectors; $180B+ TVL secured |
| **OpenZeppelin Defender AI** | OpenZeppelin | monitoring + auto-incident response (note: Defender consumer signups closed Jun 30 2025; full sunset Jul 1 2026) |

#### What AI is bad at

- Multi-contract cross-state reasoning over long call chains.
- Economic / mechanism-design bugs (KyberSwap precision, Euler donation logic).
- Anything requiring out-of-band knowledge (oracle history, governance context).
- Hallucinated findings — large LLMs still produce plausible-but-wrong "high severity" reports at non-zero rates.

The honest framing: **AI is a force-multiplier inside a human-led process, not a substitute.** Sherlock's AI beta is explicitly framed as assistive, not authoritative.

---

### 7. Severity classification — the standards that actually exist

The slide deck mentions "high severity findings" without naming a standard. Two are in active use; one is deprecated.

#### Immunefi Vulnerability Severity Classification System v2.3 (current canonical)

Hybrid impact-only matrix with override rules for elevated-privilege or uncommon-interaction requirements.

| Severity | Smart-contract impact |
|---|---|
| **Critical** | Direct theft of any user funds (in-motion or at-rest); permanent freezing; protocol insolvency |
| **High** | Temporary freezing >1h; theft of unclaimed yield or governance funds |
| **Medium** | Inability to operate due to lack of token funds; profitable block-stuffing; griefing |
| **Low** | Failure to deliver expected return without loss |
| **None / Informational** | Best-practice deviations |

Most large bounties (Optimism, Arbitrum, LayerZero) use Immunefi v2.3 verbatim with a project-specific cap.

#### OWASP Smart Contract Top 10 (2025/2026)

Published 2025 from analysis of 122 deduplicated 2025 incidents totaling ~$905M in losses. Significant change vs prior editions: **Price Oracle Manipulation** and **Flash Loan Attacks** are now their own categories rather than folded into "logic errors." Access-control bugs remain #1 cause of loss ($953.2M in 2024). Reentrancy is still on the list despite "best practices" (~$35M in 2024 reentrancy losses).

#### SWC Registry — deprecated

Last meaningful update 2020. Officially: "Readers should check external sources to clarify the relevance of existing content." Content has been folded into the EEA EthTrust Security Levels (see §10).

#### DASP Top 10 — historical only

NCC Group, 2018. Not maintained. Cited mostly for educational lineage.

---

### 8. The post-audit lifecycle: monitoring and incident response

The slide deck shows the Hypernative tweet about detecting Exactly Protocol attack 25 minutes early. In 2026 this is a saturated market.

#### The vendor landscape

| Platform | What it does | Notable |
|---|---|---|
| **Forta** | Decentralized detection bots, 10+ chains | Open-source bot SDK |
| **Hypernative** | ML-based threat detection, sub-block latency | $500–$10k+/month subscriptions |
| **Hexagate** (Chainalysis) | Pre-crime: identifies attacker wallet funding patterns *before* the exploit transaction | acquired by Chainalysis |
| **Phalcon / BlockSec** | Monitoring + automatic transaction-blocking | Stopped a flash-loan attack on **Usual Protocol** in 2025 in real time; claims >$20M prevented |
| **OpenZeppelin Defender** | Autotasks + sentinels | **Sunsetting Jul 1 2026** — migration is an industry concern |
| **Chainalysis Crypto Incident Response** | Post-hack tracing, LE liaison | follow-on revenue model |

#### What an incident response actually looks like in 2026

```
T+0     Phalcon/Hypernative/Forta alert fires
T+2m    Multisig pause-call drafted
T+5m    Protocol war-room (Telegram + on-call PagerDuty bridge)
T+10m   SEAL 911 (Security Alliance) volunteer responders engaged for triage
T+15m   Foundry/Tenderly fork to reproduce at exploit block
T+30m   Fund tracing initiated with Chainalysis / TRM / Elliptic
T+60m   Whitehat counter-exploit decision (Euler-style)
```

#### Real cases where monitoring/response saved funds

- **Curve July 2023 (Vyper reentrancy):** MEV searchers + Curve war-room (with Coinbase, BlockSec) coordinated whitehat-style counter-rescues recovering ~73% of stolen value within 60 days.
- **Euler Finance March 2023:** $197M stolen on Mar 13 2023; on-chain negotiation + reputational pressure; on Mar 18 attacker began returning ETH; by Mar 25 all major balances back; Euler ultimately recovered ~$240M (some appreciation of recovered ETH). See Euler's [War & Peace recap](https://www.euler.finance/blog/war-peace-behind-the-scenes-of-eulers-240m-exploit-recovery).
- **Usual Protocol 2025:** flash-loan attack blocked pre-execution by Phalcon.

The slide deck's argument — that monitoring is part of defense-in-depth, not a luxury — is strongly evidence-backed.

---

### 9. Insurance and risk transfer

The slide deck shows Chainproof. The full landscape:

| Provider | Type | Key trait |
|---|---|---|
| **Nexus Mutual** | Discretionary mutual (UK) | >$6B cumulative cover purchased since 2019; ~$194M active cover mid-2025; Nov 2025 Symbiotic restaking integration as reinsurance/yield layer |
| **Sherlock** | Audit-coupled | Staking pool capital backstops claims tied to audits Sherlock ran |
| **Chainproof** (Quantstamp) | Regulated insurance (Bermuda DLT Foundation) | Backed by **Munich Re reinsurance** — the bridge to traditional finance |
| **InsurAce** | Multi-chain mutual | Portfolio bundling |
| **Neptune Mutual** | Parametric | Pays on objective oracle/incident triggers — instant payout |

#### How payouts are determined

- **Discretionary (Nexus):** member vote on whether the claim falls within cover terms (smart-contract failure, custody failure, depeg).
- **Parametric (Neptune):** pre-defined oracle/incident triggers fire automatic payout.
- **Audit-coupled (Sherlock):** claims evaluated against the audit's scope.

#### Coverage gaps to teach students

- Governance attacks (often excluded).
- Oracle failures unless explicitly covered.
- "Out of scope" protocol changes after audit.
- Per-protocol caps typically 5–25% of TVL.
- Per OpenCover, **>90% of all-time DeFi insurance payouts happened in 2022 alone** — one cluster of bad events drove the industry's payout history.

The Chainproof–Munich Re relationship is the clearest example of crypto insurance plugging into traditional reinsurance markets — important for the "matures into financial infrastructure" narrative.

---

## Part II: The Modern Threat Landscape

---

### 10. Major exploits 2022–2026, mapped to slide concepts

Each entry: **incident → root cause → which slide concept it teaches**.

#### Bybit, Feb 21 2025 — $1.5B (largest ever)

Lazarus injected malicious JavaScript into the Safe{Wallet} frontend via a compromised developer machine. Bybit signers reviewed what looked like a routine cold-wallet transaction; the UI lied; the actual transaction handed `MasterCopy` ownership to an attacker contract. ~401,347 ETH ($1.4B+) plus other tokens drained.

**Maps to slides:** the auditor's "scope" discussion. The Safe contracts were heavily audited; the *frontend* serving the UI to signers was not. **Out of scope is where the bugs live.** Reference: [NCC Group's technical analysis](https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/).

#### Radiant Capital, Oct 16 2024 — $50M

UNC4736 (DPRK) phished a developer with a malware-laced PDF over Telegram (sent Sep 11 2024, five weeks before the exploit). INLETDRIFT macOS backdoor intercepted Ledger signing requests; signers blind-signed `transferOwnership()` thinking it was routine. 3-of-11 multisig compromised by 3 keys.

**Maps to slides:** defense-in-depth, but the vulnerable layer here was *operational*, not code. The audit was clean.

#### Curve Finance, Jul 30 2023 — $69M (~73% recovered)

Vyper compiler bug. Versions 0.2.15, 0.2.16, 0.3.0 incorrectly implemented `@nonreentrant` — the storage slot used for the lock was mis-allocated. pETH/ETH, msETH/ETH, alETH/ETH, CRV/ETH pools drained.

**Maps to slides:** auditor thought process must include the **toolchain underneath the source**. Source-level review and source-level FV alone would never catch this. Reference: [Vyper post-mortem](https://hackmd.io/@vyperlang/HJUgNMhs2).

#### Euler Finance, Mar 13 2023 — $197M, $240M recovered

`donateToReserves()` had no solvency check. Attacker created a self-liquidatable position by donating their own collateral, crossed an insolvency threshold, and harvested a discounted-liquidation bonus.

**Maps to slides:** **intention vs implementation.** The donation function was meant for "be nice to the protocol"; nobody checked what happens when the donor's account becomes unhealthy.

#### Ronin Bridge, Mar 23 2022 — $625M (Lazarus)

Sky Mavis controlled 4/9 validators; Axie DAO 1/9. A temporary delegation (gas-free RPC) made Sky Mavis a sign-on-behalf for Axie DAO, but the delegation was never revoked. Lazarus phished a Sky Mavis dev with a fake job offer and got 5/9 keys.

**Maps to slides:** operational hygiene. Audits cover code. They do not cover "did you remember to remove that emergency delegation?"

#### Wormhole, Feb 2 2022 — $325M (replenished by Jump)

Solana program used the deprecated `load_instruction_at` to verify that `Secp256k1` had been called previously. The check didn't validate the Instructions sysvar address — attacker passed a fake account that called Secp256k1 in an unrelated context. Bypassed signature verification entirely. Minted 120,000 wETH out of thin air.

**Maps to slides:** cross-VM understanding. EVM auditors not trained in Solana semantics will miss this class.

#### Nomad Bridge, Aug 1 2022 — $190M

An upgrade initialized the trusted-roots map with `0x00`. Because `0x00` matched the default value treated as "unproven", `process()` accepted **any** message as valid. Hundreds of wallets copy-pasted the exploit transaction — a "crowdsourced" hack.

**Maps to slides:** **code freeze and upgrade discipline.** The audited code was correct; the deployment script was not.

#### KyberSwap Elastic, Nov 23 2023 — $48M

Off-by-one rounding error in tick-boundary swap math. When `swapAmount = amountSwapToCrossTick − 1`, double-counting of liquidity happened and the post-swap pool price was incorrect. Hit Arbitrum ($20M), Optimism ($15M), Ethereum ($7M).

**Maps to slides:** **mathematical invariant testing.** Foundry/Echidna invariants over the entire pool state — not unit tests — would have surfaced this. Reference: [BlockSec breakdown](https://blocksec.com/blog/kyberswap-incident-masterful-exploitation-of-rounding-errors-with-exceedingly-subtle-calculations).

#### Ledger ConnectKit, Dec 14 2023 — $600k+ (5-hour window)

Former Ledger employee phished, NPM session token bypassed 2FA, attacker published versions 1.1.5–1.1.7 of `@ledgerhq/connect-kit` with a wallet-drainer payload. SushiSwap, Kyber, Revoke.cash, Zapper affected. Genuine fix shipped in 40 minutes; full clean-up in ~5 hours.

**Maps to slides:** **frontend supply chain is in scope**, even if it's not in your engagement letter. Subresource integrity, NPM 2FA hardware tokens, immutable IPFS-pinned bundles.

#### Multichain, Jul 5–10 2023 — $130M + $107M

CEO Zhaojun arrested by Chinese police (May 2023). The team lost MPC keys (held entirely on his personal cloud server). Either the CEO acted under duress or rugged the protocol.

**Maps to slides:** auditing **protocol governance/MPC**, not just code. Single-point-of-failure key custody is a security finding even if the contracts are flawless.

---

### 11. The "rubber stamp" problem and how to read audits critically

The slide deck mentions the discomfort of clients who "don't have the right mindset and consider smart contract audit as a rubber stamp for marketing." Let students concretize this.

#### Concrete checks when reading a published audit

1. **Audit timestamp vs deployment timestamp.** If the audit is dated months before the deployed bytecode hash, ask why.
2. **Commit hash boundaries.** Every reputable audit names exact `git` commit hashes for "audited code"; **anything outside that diff is unaudited.** Students should `diff` the deployed bytecode against the audited commit's compiled bytecode.
3. **"Out of scope" assumptions.** Look for phrases like "we assumed `OWNER_ROLE` is held by a 4-of-7 Safe" — verify that's actually true on-chain post-deployment.
4. **Resolution status.** "Acknowledged" ≠ "Fixed." Re-check whether Acknowledged findings remain acceptable in the deployed system.
5. **Severity inflation/deflation.** Compare report severities against Immunefi v2.3.
6. **"Missing pages."** Some reports show only High/Critical findings publicly. Compare draft (if leaked) and final reports — sometimes findings vanish.
7. **Audit shopping.** A protocol that quietly switched audit firms between V1 and V2 is a yellow flag.
8. **Conflict of interest.** Some firms accept token-grant payment from the audited project. Not necessarily disqualifying but should be disclosed.

#### A teaching example: the CertiK / USDH episode

The Huione Group's USDH stablecoin contracted CertiK for an audit; Huione was subsequently identified by Elliptic as running a major money-laundering marketplace. The lesson is **not** that the audit was wrong — the contracts may well behave correctly — but that **smart-contract audits assess code, not the legitimacy of the operating entity.** Audit scope is a technical artifact, not a moral endorsement.

Quantstamp's [How to Read an Audit Report](https://quantstamp.com/blog/how-to-read-an-audit-report) is a useful student-facing reference.

---

### 12. Standards: EthTrust and SCSVS

These complement the SWC Registry's deprecation.

#### EEA EthTrust Security Levels

Published by the Enterprise Ethereum Alliance. Three certification levels:

| Level | What it requires |
|---|---|
| **[S]** | Automated checks (linters, slither-style detectors) |
| **[M]** | Manual review with documented requirements |
| **[Q]** | Full logic-and-documentation review with verified formal properties |

Versions: **v2** (Apr 2023), **v3** (Mar 2025 — current). v3 tightens around access control, oracle dependence, and upgrade patterns. EthTrust absorbed all SWC entries when SWC was deprecated.

A claim of "EEA EthTrust Certified" is functionally an audit attestation aligned to specific testable requirements rather than a free-form report — useful for enterprises and regulators.

#### SCSVS — Smart Contract Security Verification Standard

Originally Securing.io (2019); now also maintained by Composable Security. More of a **developer checklist** than a certification:

1. **General** — design, upgrades, policies.
2. **Components** — common patterns (ERC20, multisig, access control) and their failure modes.
3. **Integrations** — protocols you depend on (Chainlink, Uniswap).

> **EthTrust = certification. SCSVS = checklist.** Both are complementary.

---

### 13. Audit-as-code and continuous auditing

The slide deck's "code freeze" discussion implicitly assumes a one-shot model. The reality is increasingly continuous.

#### CI integrations now standard

- **Slither in CI** — `crytic/slither-action` GitHub Action; fails the build on new high-severity findings.
- **Aderyn in CI** — replacing Mythril for Foundry repos due to speed.
- **Foundry invariants in CI** — `forge test --invariant` on every PR; nightly runs at 1000+ fuzz runs.
- **Wake / Olympix** — both ship GitHub Actions.

#### Continuous engagement models

| Model | Vendor | Shape |
|---|---|---|
| **QSP** | Quantstamp | Subscription continuous review |
| **Continuous audit** | OpenZeppelin | Long-running engagement; per-PR review |
| **Retainer** | Spearbit / Cantina | LSRs commit hours/month; PR-style review |
| **Continuous coverage** | Sherlock | Coverage stays in effect across upgrades that pass review |

#### What "good" looks like in 2026

A modern protocol's CI ideally enforces:

1. `forge test` (unit + integration + fuzz + invariant) — must pass.
2. `slither` or `aderyn` — no new high-severity detectors.
3. Mutation testing (Olympix, Vertigo) coverage threshold.
4. Optional: Certora rules on a critical subset.
5. **Bytecode diff vs last audit commit hash** — gate manual review.

Step 5 is the technical operationalization of the slide deck's **code freeze** discussion: if deployed bytecode differs from audited bytecode, the audit's safety claim is void. CI can enforce this mechanically.

---

### 14. Privacy-aware auditing (zk circuits)

Auditing zk-circuits (Aztec, zkSync Era, Scroll, Polygon zkEVM, StarkNet, Linea) is a separate discipline from auditing Solidity. ~78% growth in attacks on ZK implementations since 2023; **~97% of ZK circuit vulnerabilities are under-constrained-bug class.**

#### Tools

- **Picus** — symbolic execution + SMT for Circom; verifies circuits aren't under-constrained.
- **Circomspect** — Trail of Bits AST-level static analyzer for Circom.
- **Coda (Veridise)** — formal-verification approach.
- **Korrekt** — combined approach.
- **zkFuzz (CCS 2025)** — fuzzing pipeline; ~96% bug detection on small circuits, ~66% on large ones.
- **Ecne** — abstract interpretation.
- **ZKAP, ConsCS** — newer Circom-focused detectors.

#### Specialist firms

- **zkSecurity** — pure-play zk auditor; runs the ZK/SEC Quarterly blog and Circomscribe.
- **Zellic, Veridise, Trail of Bits** — bench depth on circuits.

#### Soundness vs completeness

- **Soundness:** "no false proof can be generated" — circuit must over-constrain enough that invalid witnesses fail. Under-constrained circuits *break soundness*.
- **Completeness:** "every valid witness produces a valid proof" — over-constrained circuits *break completeness*.

Auditing a circuit means proving both for a specific spec. **RISC Zero** is documenting its path to the first formally verified RISC-V zkVM (target 2026) — likely the first production-grade FV-of-zkVM result.

---

### 15. Post-Cancun / Pectra-era considerations

#### EIP-1153 (Transient Storage) — Cancun, Mar 13 2024

`TSTORE` / `TLOAD` opcodes; 100 gas; transaction-scoped, cleared on transaction end.

**New reentrancy class:** transient storage is **not** discarded on revert (unlike memory). Using it for a reentrancy lock cleared at end-of-call is safe; using it for cross-call state that doesn't reset on revert can introduce novel reentrancy. ChainSecurity disclosed a **TSTORE low-gas reentrancy** class — lack of a minimum-gas requirement in `TSTORE` creates new re-entry scenarios. **EIP-7971** (Jun 2025 draft) proposes hard limits to mitigate. Reference: [ChainSecurity blog](https://www.chainsecurity.com/blog/tstore-low-gas-reentrancy).

**Uniswap V4** is the canonical production user — "Flash Accounting" uses `TSTORE` to defer settlement to a single transfer per token. Audits of v4-style hook contracts must trace transient state across hook callbacks.

#### EIP-7702 (Set Code Transaction) — Pectra, May 2025

Allows EOAs to delegate to a contract — smart-account-on-EOA without ERC-4337 deployment.

**New attack surfaces:**

- Storage collision when the same EOA delegates to a different contract with overlapping slots.
- Once a phishing victim signs a single authorization tuple, **every subsequent invocation** of their account runs attacker bytecode.
- **Aug 2025 phishing wave:** $1.54M campaign exploiting 7702 batch execution. One study found **97% of EIP-7702 delegations** observed in the wild were "sweepers" — auto-drain wallets. (Huang et al., USENIX Security 26 paper.)
- **`tx.origin` security assumption is broken** in 7702 mode — many DeFi/governance contracts that gate on `tx.origin == msg.sender` need re-audit.
- Interaction with **ERC-4337 paymasters** removes the gas barrier; bundlers become unintentional activation carriers.

**Audit checklist for 7702-aware contracts:**

1. Treat any EOA caller as potentially smart-account-delegated.
2. Avoid `tx.origin` checks for security.
3. Verify storage layout if the contract is intended as a 7702 delegation target.
4. Re-audit ERC-4337 paymaster interaction.

#### Blob-related (EIP-4844)

For rollup operators: blob availability and KZG verification correctness. For app-layer auditors: rare unless the protocol pulls blob data via state proofs.

---

### 16. Bug bounty program design

#### Tier sizing — the 2026 market consensus

| Severity | Reward (USD) | Typical cap |
|---|---|---|
| Critical | $50k – $10M | 10% of economic damage at risk |
| High | $20k – $250k | $250k |
| Medium | $5k – $50k | $50k |
| Low | $1k – $5k | $5k |

#### Well-designed examples

- **Optimism** — minimum **$75,000** for Critical; cap at 10% of economic damage; pays in USDC; uses Immunefi v2.3.
- **Arbitrum** — Immunefi-administered, USDC-denominated.
- **LayerZero** — top-tier Critical payouts, well-defined PoC requirements.
- **Compound** — community-governed bounty proposal; staked funds backstop the bounty.
- **MakerDAO/Sky** — caps at $10M Critical.

#### Anti-patterns

- Tiny critical caps (e.g., $25k Critical for a $500M-TVL protocol) — guarantees attackers prefer exploiting over disclosing.
- "We reserve the right to determine severity at our discretion" with no published criteria.
- Discord-only intake (no PoC requirements doc) — no audit trail.
- No commitment to disclosure timeline.
- Out-of-scope contracts that hold the actual TVL.

#### What a working bounty program requires

A bounty program **only works** if:

1. **Reward > exploit profit at the protocol's TVL.**
2. **Severity definitions are public** and hyperlinked to Immunefi v2.3.
3. **Pre-audit, not post-audit, only.** Bounties don't replace audits.
4. **Funded by a multisig with reserved capital**, not a "we'll pay if we have it" promise.

---

## Closing: three meta-points for the lecture

### A. The audit boundary is shrinking; defense-in-depth is the actual product

The slide deck's pipeline (best practices → automated → audit → monitoring → insurance) is now an explicit market with 3–5 vendors per layer. An audit is no longer the final word; it's the middle of a five-step process. *No single layer is sufficient; every layer is necessary.*

### B. The threat model now spans code, infra, supply chain, social engineering

Of 2024's top losses, the majority were **not** smart-contract bugs but private-key compromises and social engineering — Bybit Safe UI, Radiant PDF, Ronin job-offer phish, Multichain CEO server, Atomic Wallet derivation. The auditor's "intention vs implementation" thought process must now extend to operational security and frontend supply chain — both formerly out-of-scope.

### C. FV + AI are eating the easy bugs; the value is in mechanism design

Reentrancy, integer overflow, missing access control — increasingly caught by Slither/Aderyn/Olympix and Certora rules in CI. The bugs that still ship to production are **economic / mechanism-design bugs**: KyberSwap precision, Euler donation, Curve compiler. Future auditors specialize in invariants, mathematical models, and protocol-level threat models — not in spotting `external` keyword omissions.

---

## Discussion questions for class

1. The slides argue that audits cannot guarantee bug-freedom because of complexity, composability, etc. How does *formal verification* change that argument, if at all? What changes if Aave runs ~1000 Certora rules continuously in CI?

2. A protocol can spend $200k on a Trail of Bits review *or* $200k as a Code4rena contest pool *or* $200k on a 12-month QSP retainer. Under what conditions does each option win?

3. The Bybit hack ($1.5B) didn't break any audited code. Where would you place the failure in the slide deck's defense-in-depth diagram, and which layer should have caught it?

4. The Vyper/Curve compiler bug breaks the assumption that "verifying the source proves the deployed bytecode." How does this change your audit workflow? What level of the toolchain do you need to verify?

5. Why is `tx.origin == msg.sender` broken under EIP-7702, and how would you migrate a governance contract that relies on this check?

6. A contest-platform finding has a different epistemic status than a finding from a traditional firm. Which is more credible to a third party, and why?

---

## Further reading

### Standards and frameworks
- OWASP Smart Contract Top 10 — https://scs.owasp.org/sctop10/
- Immunefi Severity v2.3 — https://immunefi.com/immunefi-vulnerability-severity-classification-system-v2-3/
- EEA EthTrust Security Levels — https://entethalliance.org/specs/ethtrust-sl/v2/
- SCSVS — https://github.com/ComposableSecurity/SCSVS

### Platforms
- Code4rena docs — https://docs.code4rena.com/
- Sherlock docs — https://docs.sherlock.xyz/
- Cantina — https://cantina.xyz/
- Spearbit — https://spearbit.com/

### Tools
- Trail of Bits Medusa launch post — https://blog.trailofbits.com/2025/02/14/unleashing-medusa-fast-and-scalable-smart-contract-fuzzing/
- Halmos — https://github.com/a16z/halmos
- Kontrol/KEVM — https://docs.runtimeverification.com/kontrol
- Certora Prover (open-source announcement) — https://www.certora.com/blog/certora-goes-open-source
- Aave Continuous FV (governance post) — https://governance.aave.com/t/security-and-agility-of-aave-smart-contracts-via-continuous-formal-verification/10181
- Wake (Ackee) — https://github.com/Ackee-Blockchain/wake
- Aderyn (Cyfrin) — https://github.com/Cyfrin/aderyn
- Olympix — https://www.olympix.ai/
- Heimdall-rs — https://github.com/Jon-Becker/heimdall-rs
- Dedaub Decompiler — https://app.dedaub.com/decompile

### Incident post-mortems (high-signal reading)
- Bybit (NCC Group) — https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/
- Curve / Vyper compiler — https://hackmd.io/@vyperlang/HJUgNMhs2
- Euler "War & Peace" — https://www.euler.finance/blog/war-peace-behind-the-scenes-of-eulers-240m-exploit-recovery
- Radiant Capital (rekt.news) — https://rekt.news/radiant-capital-rekt2
- KyberSwap (BlockSec) — https://blocksec.com/blog/kyberswap-incident-masterful-exploitation-of-rounding-errors-with-exceedingly-subtle-calculations
- Wormhole (Halborn) — https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022

### Audit-reading guidance
- Quantstamp "How to Read an Audit Report" — https://quantstamp.com/blog/how-to-read-an-audit-report

### Cancun/Pectra audit considerations
- TSTORE low-gas reentrancy (ChainSecurity) — https://www.chainsecurity.com/blog/tstore-low-gas-reentrancy
- EIP-7702 phishing study — https://arxiv.org/html/2512.12174v1

### Annual hack telemetry
- Chainalysis 2024/2025 hack stats — https://www.chainalysis.com/blog/crypto-hacking-stolen-funds-2025/
