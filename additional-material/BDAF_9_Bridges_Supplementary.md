# Cross-Chain Bridges — Supplementary Material

CSIC30161 Blockchain Development and Fintech | Martinet Lee

> Companion to the lecture deck *"Bridges"*. The slides develop the threat model from first principles: atomic swaps via HTLCs, the classic lock-and-mint architecture (custodian + debt issuer + communicator/oracle), the L2Bridge Risk Framework taxonomy, the decentralization spectrum of the off-chain communicator, and four categories of attack — on the **custodian**, the **debt issuer**, the **communicator**, and the **user-facing interface**. This document goes deeper into how that threat model has played out 2022–2026, with concrete protocols, hacks, and the new bridge architectures that have emerged since the slides were last updated.

---

## Part I: The Threat Model Still Holds — But the Architecture Has Changed

---

### 1. The full bridge taxonomy in 2026

The slide deck builds up the "classic" bridge: **custodian + debt issuer + communicator**. By 2026 there are **six structural archetypes** that the same four-component mental model still classifies cleanly. Every modern bridge is some assembly of these.

| Archetype | Typical example | Capital | Latency | Trust root |
|---|---|---|---|---|
| **Lock-and-Mint** (slide's "classic") | Old Multichain, Wormhole-wrapped assets | Locked 1:1 | Minutes | Custodian + oracle |
| **Burn-and-Mint (canonical issuer)** | CCTP (USDC), USDT0, Wormhole NTT | Zero | Seconds–minutes | Issuer |
| **Liquidity Network** | Stargate v2, Hop, cBridge | LP-locked | Seconds | Messaging + LP solvency |
| **Generic Message-Passing (GMP)** | LayerZero v2, Wormhole, Axelar, CCIP | None | Variable | Verifier set |
| **Intent / Solver-based** | Across V4, deBridge DLN, UniswapX cross-chain | Solver inventory | Sub-second | Settlement oracle |
| **Canonical Rollup Bridge** | OP `StandardBridge`, zkSync, Polygon zkEVM | None | Optimistic 7d / ZK ~30min | Rollup security |

Why this matters for the slide deck's framing: the classic lock-and-mint pattern is *deprecated for major assets in 2026*. The dominant patterns now are **issuer-canonical burn-and-mint** for tokens (USDC, USDT, WBTC) and **GMP + intents** for everything else. Cumulative bridge exploit losses 2021–2024 are **~$2.8B+** — the migration away from lock-and-mint is the industry's response to that loss history.

---

### 2. Generic Message-Passing (GMP) — the substrate of modern bridges

GMP protocols are the "communicator" layer of the slide deck, generalized: arbitrary cross-chain calls, not just token transfers. Tokens move *atop* the messages. Five protocols matter.

#### 2.1 LayerZero v2 — DVNs and modular security stacks

LayerZero v2 (2024) decomposed the communicator into:

- **Endpoint** — immutable on-chain entry point.
- **MessageLib Registry** — append-only verification modules.
- **DVNs (Decentralized Verifier Networks)** — *permissionless* verifier sets. Each application picks its DVN combination. A DVN can internally use BFT consensus, MPC, ZK, or even a single multisig.
- **Executors** — permissionlessly deliver the call after verification; they do not validate.
- **OApp Security Stack** — per-application "X required + Y-of-N optional" config (e.g., Stargate v2 uses 2/2 of {LayerZero DVN, Nethermind DVN}).

DVN operators in 2026 include LayerZero Labs, Google Cloud, Polyhedra (zkLightClient), Nethermind, Animoca. LayerZero's published 2025 stats: **$225B total value moved**, **159M+ messages**, **701+ apps**, **168 chains**. The OFT (Omnichain Fungible Token) standard alone — 733+ tokens including USDT0 and PYUSD — accounts for **$166.9B** of cross-chain transfer volume. ([LayerZero — *25 stats explaining how crypto accelerated in 2025*](https://layerzero.network/blog/25-stats-explaining-how-crypto-accelerated-in-2025).) The single biggest LayerZero-related security incident, the KelpDAO/rsETH exploit (April 2026, ~$290M), is treated separately in `BDAF_9b_LayerZero_Incident.md`.

> **Maps to slide concept:** the "decentralization spectrum of the off-chain communicator." The DVN model lets the *application*, not the bridge protocol, choose the trust model. A high-value protocol can pick a 3-of-3-DVN-from-three-different-ecosystems stack; a tiny app can pick a single DVN. The spectrum is now per-app.

#### 2.2 Wormhole — Guardians and the NTT framework

**19 Guardians** (Jump, Certus One, Everstake, Staked, Chorus One, Figment, P2P, Forbole, Triton, etc.) sign with a **13-of-19 threshold** scheme producing a **Verified Action Approval (VAA)**.

**NTT (Native Token Transfer)** ships two flavors:
- **Hub-and-Spoke** — existing ERC-20s: lock on hub, mint elsewhere.
- **Burn-and-Mint** — newly issued tokens.

Two core abstractions:
- **Manager** — handles supply changes (burn/lock + mint/unlock) and per-rate-limit logic.
- **Transceiver** — `ITransceiver` pluggable backend; default is Wormhole core, but issuers can layer Axelar, LayerZero, or custom ZK light clients in series for redundancy.

Adopters include Lido `wstETH` cross-chain, Ethena `ENA` on Solana, and the `W` token.

#### 2.3 Axelar — a Cosmos-SDK PoS L1 doing cross-chain

Full Cosmos-SDK proof-of-stake L1 with **~75 validators**, dynamically rotated, plus the **Interchain Amplifier** (any chain can be added by deploying its own gateway+verifier without core protocol upgrades) and **Interchain Token Service (ITS)** — Axelar's NTT-equivalent supporting 15+ chains by Q3 2025. Compromising the bridge requires compromising a majority of 75 staked validator keys.

#### 2.4 Hyperlane — Modular ISMs as security legos

Uses **Interchain Security Modules** (ISMs) as composable smart-contract building blocks: `MultisigISM`, `OptimisticISM`, `AggregationISM` (X-of-Y), `RoutingISM` (per-message branching), `WormholeISM`, `CCIPReadISM`. Apps assemble their *own* security stack. Hyperlane is fully permissionless — anyone can spin up a "Sovereign Consensus" deployment with their own validator set.

#### 2.5 Chainlink CCIP — dual DON + the Risk Management Network

Three networks running in parallel:
- **Committing DON** — posts Merkle roots to the Commit Store on the destination.
- **Executing DON** — independently executes messages.
- **Risk Management Network (RMN)** — *separate* node operators (no overlap with the DONs); each RMN node "blesses" Merkle roots only after independently verifying source events, and can "curse" the system to globally pause CCIP if it sees an anomaly. The RMN is intentionally written in a *different language and stack* — defense-in-depth against common-mode bugs.

**CCT (Cross-Chain Token)** standard introduced in CCIP v1.5 (2024) gives token issuers a self-service way to integrate (token pools, custom rate limits, ACE compliance hooks). 2025 cross-chain CCIP value transferred surged ~1,972% YoY to ~$7.77B.

> **Maps to slide concept:** the slide tells students the communicator is the security-critical component. CCIP's RMN is the explicit recognition of this — a *separate* committee whose only job is to second-guess the main communicator. It is the architectural counter-pattern to Multichain's "one human, one machine" failure mode.

#### 2.6 Connext (Amarok / xCall)

`xCall` is the only primitive — analogous to a Solidity `CALL` but cross-chain. Implements `IXReceiver` on the destination. Connext piggybacks on **canonical rollup bridges** (the security floor is "the worst rollup in your route"). xERC20 (ERC-7281 — see §10) was largely championed by Connext.

---

### 3. Light-client bridges — when the on-chain communicator IS the verifier

The slide deck mentions "Light Client on chain?" almost in passing. In 2026 it is one of the two dominant trust-minimization patterns.

#### 3.1 ZK light-clients

A **block-header relay network** generates SNARK proofs of header validity off-chain; the destination chain runs a cheap on-chain verifier. The economic breakthrough was 2023–2024 — naive verification of an Eth2 sync committee BLS aggregate costs ~10M+ gas; a SNARK reduces it to **<300k gas**.

| Project | Source(s) | Tech |
|---|---|---|
| **Polyhedra zkBridge** | EVM ↔ EVM, BTC, BNB, Solana | deVirgo + 2-layer recursion; also operates as a LayerZero DVN |
| **Succinct Telepathy / SP1** | Ethereum ↔ EVM | SP1 RISC-V zkVM; verifies Eth2 sync committee BLS aggregates |
| **Electron Labs** | Cosmos ↔ EVM | SNARK over Tendermint Ed25519 signatures |

Off-chain proving cost ~30s–2min on a single GPU. Used by Hashi (Gnosis aggregator) and various OP-Stack chains.

#### 3.2 Optimistic light clients

Nomad (pre-hack), Optics, and the Hashi aggregator's optimistic ISM accept a header after a fraud-proof window. The Nomad disaster (see §6) illustrates how brittle they can be when initialization is botched.

#### 3.3 IBC — the philosophical counter-design

Each Cosmos chain runs a **light client of every counter-party chain on-chain** (Tendermint commits are cheap enough to verify directly). A "channel" is a pair of light clients. Relayers can be permissionless because they cannot lie — bad packets fail verification on the destination. ~$50B+ cumulative volume across 115+ chains, **zero loss-of-funds bridge exploits since 2021 launch**. IBC v2 (2025) extends "IBC everywhere" to non-Cosmos chains.

#### 3.4 Rainbow Bridge (NEAR ↔ Ethereum)

Two on-chain light clients: an Ethereum light client deployed on NEAR (verifies Ethash + longest-chain), and a NEAR light client on Ethereum that *optimistically* accepts NEAR checkpoints every 4h with a fraud-proof window (because verifying NEAR's BLS signatures on Ethereum directly is too expensive).

#### 3.5 ZK vs Optimistic light clients — the real tradeoff

| | ZK | Optimistic |
|---|---|---|
| Latency | Proof time (~minutes) | Challenge window (hours – 7d) |
| On-chain cost | ~50–500k gas | Tiny |
| Liveness assumption | None | One honest watcher |
| Failure mode | Soundness break = total failure | Silent griefing if no challenger |

**Discussion question:** The slide deck argues that an "off-chain communicator" determines decentralization. With on-chain ZK light clients, the communicator becomes a *cryptographic* check rather than a *governance* check. Does this collapse the decentralization spectrum or reshape it?

---

### 4. Intent-based bridges — the new dominant UX pattern

The slide deck teases "intent-based bridges" at the end without unpacking. They have eaten most of the user-facing bridge UX since 2024.

#### Architecture template

```
1. User signs a typed-data order on Chain A
       (origin escrow, output spec, deadline, max slippage)
2. A solver/filler network sees the order over a public mempool/auction
3. Winning solver pays the user from THEIR OWN inventory on Chain B  ← "filling"
4. A settlement layer eventually reimburses the solver from the escrow
       (UMA Optimistic Oracle, ZK proof, canonical bridge, finality wait)
```

Note: from the user's perspective the destination payout happens *before* the source bridge finalizes. The bridge's communicator is no longer in the user's critical path.

#### Key projects

- **Across V4** — UMA Optimistic Oracle settlement; sub-2s median fill (sometimes <1s); >$20B moved with 14M transactions; **never been hacked** as of April 2026; median fee ~$0.04.
- **deBridge DLN** — *0-TVL* design (no protocol-owned liquidity); competing solvers; >$9.96B and zero exploits. "Fulfill-first, settle-later" with on-chain validator verification of the fulfillment receipt. Heavily used for stablecoin and Solana↔EVM swaps.
- **UniswapX cross-chain** — uses the ERC-7683 `CrossChainOrder` struct (see §10); fillers are mostly market-makers (Wintermute, GSR). Composes with Uniswap V4 hooks.
- **CoW Protocol cross-chain** — batch-auction matching plus solver-fulfilled bridging; July 2025 hit $9B/month for the first time. Bonus: two opposite-direction bridge intents can be netted off entirely (coincidence-of-wants).
- **Bungee / Socket** — aggregator that *pulls* quotes from multiple intent venues; emphasizes a "modal" UI showing solver competition.
- **LiFi** — broader bridge+DEX aggregator across 60+ chains; uses EIP-2535 diamond pattern so individual bridge facets can be hot-swapped.

> **Maps to slide concept:** the user-facing interface is the most exposed part of an intent-based system. Solver competition and settlement disputes are the new attack surface — see §9 on cross-chain MEV.

#### MEV implications — cross-chain sandwiches

Recent work (arxiv 2511.15245) documents bots earning **21.4% margins** (vs 0.8% for equivalent same-chain bots) by reading the source-chain `BridgeInitiated` event — which leaks the user's intent — *before* the destination tx lands. ~$869M of cross-chain arbitrage was identified in 2024–2025; spreads run 0.5–5% with far less competition than mainnet. Mitigations: encrypted mempools (Shutter), commit-reveal, threshold encryption, intent designs that pre-commit the solver's output price.

---

### 5. Canonical rollup bridges — when the rollup IS the security

The slide deck doesn't distinguish these. They're worth their own treatment because the security model is fundamentally different.

#### Optimistic rollup bridges
- **OP Stack `StandardBridge`** — `L1StandardBridge` ↔ `L2StandardBridge`. Deposits via `depositERC20`; withdrawals are *three-step*: `initiateWithdrawal` → `proveWithdrawalTransaction` → `finalizeWithdrawalTransaction` after the **7-day challenge period**.
- **Arbitrum `L1ERC20Gateway`** + `L1GatewayRouter` — same pattern, 7-day window.
- **Fast bridges as overlays.** Hop, Across, Stargate-stable pools sit *on top* of canonical bridges. Hop's "Bonders" front liquidity in seconds; settlement on L1 happens asynchronously.

#### ZK rollup bridges (no challenge window)
- **zkSync Era** — publishes state diffs (compressed); withdrawal usually ≥3h depending on proof cadence.
- **Polygon zkEVM / Linea / Scroll** — withdrawal ≤30 min once a validity proof finalizes. Scroll bridge is bytecode-equivalent zkEVM; Linea is Type-2.
- **StarkNet** — STARK-based; withdrawals via `withdraw_from_l2` then `consume_message` on L1 after proof.

#### Polygon AggLayer — the "unified canonical"

A *cross-rollup* canonical bridge: the AggLayer aggregates **pessimistic proofs** from each connected CDK chain. The pessimistic proof is a cryptographic attestation that no chain can withdraw more than it has deposited into the unified bridge — making the multistack network robust even if one connected chain has a bug. v0.1 (Feb 2024) brought the unified bridge; v0.2 (Feb 2025) added pessimistic proofs to mainnet; v0.3 (June 2025) made it multistack (OP Stack, Arbitrum Orbit, etc.).

> **Maps to slide concept:** for canonical rollup bridges, "the custodian" *is* the rollup itself — not a multisig. Compromising the bridge requires compromising the rollup's fault-proof / validity-proof system. This is the "natively verified" tier of the L2Beat framework — strictly stronger than any external bridge.

---

### 6. Catastrophic bridge exploits — the four-bucket map

Every major bridge hack 2021–2025 maps cleanly onto the slide deck's four-category threat model. None of them required a new category.

| Hack | Date | Loss | Root cause | Slide bucket |
|---|---|---|---|---|
| **Poly Network** | Aug 10 2021 | ~$611M (returned) | `verifyHeaderAndExecuteTx` allowed arbitrary calldata into `EthCrossChainData.putCurEpochConPubKeyBytes`, letting attacker rotate the keeper set | **Communicator** — arbitrary callData |
| **Wormhole** | Feb 2 2022 | $325M (~120k wETH) | Solana program's deprecated `load_instruction_at` did not check the Instructions sysvar address; attacker passed a fake sysvar that "looked" like the real signature program → `verify_signatures` thought ed25519 verify ran | **Debt Issuer** — signature-verification bypass |
| **Ronin** | Mar 23 2022 | $625M | 5-of-9 PoA validators; Sky Mavis controlled 4, Axie DAO 1; Sky Mavis ran a "free RPC" for the DAO and forgot to revoke that proxy after a Discord-based social-engineering compromise → attacker signed with 5 keys | **Custodian** — privileged-address takeover |
| **Harmony Horizon** | Jun 24 2022 | ~$100M | 2-of-5 multisig; Lazarus phished >2 keys. Hardened post-hack to 4-of-5. | **Custodian** — multisig with too few signers |
| **Nomad** | Aug 1 2022 | ~$190M | Routine upgrade initialized `acceptableRoot[0x00] = true`. `Replica.process()` looked up message hashes that defaulted to `0x00` when missing → *every* unproven message was accepted. Any wallet could `process()` someone else's bridge tx by swapping the recipient. ~300 looters. | **Communicator** — only-checking-the-zero-default bug; **Debt Issuer** trust assumption broken |
| **Heco / HTX** | Nov 22 2023 | ~$87M | Operator key compromise (Justin Sun-affiliated) | **Custodian** — privileged-address |
| **Orbit Chain** | Dec 31 2023 | ~$81.5M | 7-of-10 multisig signers compromised; later attributed to former CISO who altered firewall rules 2 days post-resignation | **Custodian** — insider |
| **Multichain / Anyswap** | Jul 6 2023 | ~$130M | CEO "Zhaojun" was the *sole* holder of MPC key shares; arrested in China and could not be reached → keys lost; suspected inside drain | **Custodian** — MPC-operator-equals-one-person |
| **Radiant Capital** | Oct 16 2024 | ~$53M | 3-of-11 Gnosis Safe; UNC4736 (Lazarus) malware intercepted Safe Tx-Builder UI on signers' machines and surfaced *correct* details on screen while pushing a `transferOwnership()` payload to the Ledger — Ledgers don't parse Safe blob, so signers blind-signed | **Custodian** — privileged-address via signing-UI compromise |
| **Wormhole UUPS proxy near-miss** | 2022 (white-hat) | Would have been catastrophic | Botched upgrade left the implementation `initialize()` callable; whitehat could become guardian | **Custodian** — unprotected initializer |

#### Two patterns the slides predict perfectly

The slide "Attacks on Custodian (1)" — *take over privileged addresses* or *change the address of privileged addresses* — accounts for **Ronin, Harmony, Heco, Orbit, Multichain, Radiant**. The slide "Attacks on Custodian (2)" — *craft proofs that pass verification* — accounts for **Wormhole** (Solana sysvar) and **Nomad** (root = `0x00`). The slide "Attacks on Communicator" — *trick into forwarding invalid messages* — accounts for **Poly Network**.

The slide deck's threat tree is complete. What changed is *which bucket* the industry kept failing in (custodian-takeover via off-chain compromise dominates 2023–2025).

---

### 7. The L2Beat Bridge Risk Framework — how to read the dashboard

The slide deck shows the L2Bridge Risk Framework at a high level. Two pieces are worth being explicit about for students.

#### Top-level categories (how messages are validated)

1. **Externally Verified** — an external committee/multisig/MPC signs off (most lock-and-mint bridges, classical Wormhole, Multichain). Highest trust assumption.
2. **Optimistically Verified** — fraud-proof window with one honest watcher (Nomad, Optics, Hashi optimistic ISM).
3. **Natively Verified** — light-client (IBC, zkBridge, Telepathy) or canonical rollup bridges. Lowest trust assumption.
4. **Hybrid** — combinations (e.g., LayerZero with a ZK-DVN + a multisig DVN).

#### Risk dimensions (each scored Low / Medium / High)

1. **Validation** — how messages are checked on the destination.
2. **Source-of-funds** — what backs the wrapped IOU (1:1 escrow vs LP pool vs issuer).
3. **Destination-of-funds** — recipient asset's redemption guarantees.
4. **Validator failure** — what happens if k-of-n validators sign a malicious message.
5. **Upgradeability** — who can upgrade the bridge contracts and on what timelock.

L2Beat additionally classifies *assets on L2s* as **Canonically Bridged**, **Natively Minted** (issuer is on the L2), or **Externally Bridged**. Reading the dashboard, "External Bridge" warning is the **single most predictive feature of historical loss-of-funds**.

> **Discussion question:** A protocol can issue itself as Canonically Bridged (e.g., USDC via CCTP on Optimism) or Externally Bridged (USDC.e via Hop). The user-facing UX may look identical. What disclosures would you require, and where does the responsibility sit — protocol, bridge, or wallet?

---

### 8. Native Token Transfer (NTT) — why issuer-canonical won

The dominant *post-2023* design pattern for token-issuer-controlled cross-chain assets.

| Framework | Operator | Mode | Verifier model |
|---|---|---|---|
| **Circle CCTP V2** | Circle (centralized) | Burn-and-mint | Circle attestation + per-chain MessageTransmitter; Fast Transfer mode <30s |
| **Wormhole NTT** | Token issuer | Both modes | 13-of-19 Guardians + optional add'l transceiver |
| **LayerZero OFT** | Token issuer | Burn-and-mint | OApp-configured DVN set |
| **Chainlink CCT (CCIP)** | Token issuer | Both modes | CCIP DON + RMN, optional Token Developer Attestations |
| **BitGo WBTC** | BitGo (centralized) | Mint via BitGo custody (lock-and-mint flavor) | BitGo |

#### Why the issuer-canonical pattern won

1. **Eliminates wrapped fragmentation.** Pre-CCTP, USDC on Polygon could simultaneously be Polygon-canonical USDC, anyUSDC, ceUSDC, Wormhole-USDC — each backed differently, each illiquid, none truly fungible.
2. **Trust set collapses to one entity.** The issuer is *already* the trust root. Adding a multisig bridge between users and issuer doesn't increase decentralization — it adds a second trusted party. Issuer-controlled NTT *strictly removes* trust assumptions.
3. **Compliance hooks.** Issuers can implement freeze lists, sanctions screens, and transfer rules consistently across chains only if they own the cross-chain layer.
4. **Regulatory pressure.** MiCA (Europe, in force 2024) and the GENIUS Act (US, 2025) effectively require stablecoin issuers to be the cross-chain operator of their asset.

#### CCTP V2 specifics

Fast Transfer mode brings settlement from V1's 13–19 minutes (Ethereum hard finality wait) down to **seconds** via "soft-finality + Circle insurance pool." Hooks let arbitrary calldata execute on the destination after mint. CCTP V1 is being deprecated July 31, 2026.

#### The WBTC controversy — why issuer-canonical is also issuer-jurisdiction-dependent

In 2024 BitGo announced custody rotation to a Hong Kong joint venture (BitGlobal). MakerDAO and Aave debated removing WBTC as collateral. Coinbase launched **cbBTC** (issuer-canonical, by Coinbase). Threshold's **tBTC** offers a more decentralized 51-of-100 ECDSA threshold-signed alternative. The episode illustrated that *issuer-canonical = issuer-jurisdiction-dependent*, which can be a security and regulatory feature or a bug depending on the user.

---

## Part II: New Standards and the Evolving Threat Surface

---

### 9. MEV, censorship, and reorg attacks across bridges

The slide deck's "Attacks on Communicator (2)" section flags 51% attacks on the source chain. The full picture in 2026:

#### Cross-chain sandwich attacks

A bot reads the user's source-chain `BridgeInitiated` event, predicts the destination AMM swap output, and front-runs on the destination (still in the destination's mempool). Measured 21.4% margins. Most acute on liquidity-network bridges with predictable destination logic. Mitigations: encrypted mempools (Shutter), commit-reveal, threshold encryption, intent-based architectures where the solver guarantees an output price.

#### Reorg risk in lock-and-mint — concrete history

The slide's "51% on source chain" attack is not theoretical:

- **Polygon PoS** had ~670 reorgs in 125 days mid-2022; pre-Delhi (Jan 17 2023) reorgs of up to **128 blocks** were possible. Hayden Adams (Uniswap) publicly criticized Polygon after a **157-block reorg** occurred *despite* Delhi. Bridges adapted by waiting 1+ minute for probabilistic finality. AggLayer now refuses to credit deposits until L2 → Ethereum finality.
- **Solana** had a 5h outage Feb 6 2024 (LoadedPrograms bug) and Feb 25 2023 outage (Turbine block-propagation bug). Solana halts rather than forks (CP > AP), but bridges still must wait *post-restart* due to potential rebroadcasts. Wormhole, deBridge, Mayan all wait ≥32 confirmations post-restart.
- **Ethereum finality bug** (May 2023) — temporary loss of finality for 25 minutes. Vitalik publicly noted bridges should be designed to handle this. Most have moved from "12-block confirmation" defaults to "wait for finalized checkpoint" defaults.

> **Maps to slide concept:** when the source-of-truth is another blockchain, "history can be rewound." The slide makes this point philosophically; the empirical record demands concrete confirmation depths and a fallback for finality-loss events.

---

### 10. The new standards: ERC-7683, ERC-7281, RIP-7212, ERC-3643

Standards composition is now where most bridge security work happens.

#### ERC-7683 — Cross-chain Intents

Standardized order struct (`CrossChainOrder` + `ResolvedCrossChainOrder`) and two interfaces:
- `IOriginSettler` — escrows user funds and emits an `Open` event on the source.
- `IDestinationSettler` — pays the user on the destination and emits the receipt.

Co-authored by Uniswap and Across; UniswapX v2 and Across V4 are reference implementations. Means a single solver implementation can serve any compliant intent venue. Ratifies the intent-bridge architecture from §4.

#### ERC-7281 — xERC20

Lockbox + xERC20 token; **per-bridge configurable mint/burn rate limits on-chain**. A token can list "Hop is allowed to mint up to 1M/day, LayerZero up to 5M/day" — limiting the blast radius of any single bridge hack to that bridge's daily ceiling. Adopted by Connext, Frax, Threshold (tBTC), and others.

> **Maps to slide concept:** the slide deck's threat tree treats each bridge as one trust unit. xERC20 is the token-issuer's response: split the trust by bridge with *on-chain* enforcement of how much each can mint.

#### RIP-7212 — secp256r1 (P-256) precompile

Address `0x0000…0100`, **3450 gas** per verification. Live on OP Mainnet, Base, Arbitrum, Polygon zkEVM, zkSync. Unlocks **Passkey-signed transactions** (Apple Secure Enclave, Android Keystore, YubiKey, WebAuthn) — meaning a user can sign a cross-chain bridge tx with FaceID and have the signature verified on-chain. Critical for chain-abstraction wallets (Coinbase Smart Wallet, Daimo, Clave).

#### ERC-3643 — permissioned tokens

Originally the T-REX security-token standard; increasingly used for compliance-aware cross-chain transfers (KYC, sanctions, transfer rules). Important for tokenized real-world assets (Ondo, BUIDL) bridging across chains.

---

### 11. Account abstraction + bridges — chain abstraction stacks

#### Cross-chain ERC-4337

A `UserOperation` can contain calldata that triggers a bridge. **Paymasters can sponsor gas on the destination chain** ("user pays no destination gas") — a major UX win.

#### The 2026 stacks

- **NEAR Chain Signatures** — NEAR validators run an MPC TSS (live since Aug 2024). A NEAR account can request that MPC sign an Ethereum/Bitcoin/Solana transaction on its behalf, effectively *deriving* externally-controlled accounts on every chain from one NEAR account. Trust model: NEAR validator-set integrity.
- **Particle Network** — MPC-TSS social login + Universal Accounts; UserOperations span chains automatically.
- **OneBalance** — "Credible Accounts" API: surfaces a single balance across 15+ chains.
- **Safe + ERC-4337** — Safe7579 module turns Safes into ERC-4337 accounts; combined with a cross-chain message bus, Safe owners can recover or control the same Safe address on multiple chains.

#### Smart-wallet mesh (Coinbase Smart Wallet, Privy, Clave)

Use EIP-7702 (live on Ethereum since Pectra) + RIP-7212 to give every passkey-equipped phone a deterministic smart-wallet address across all chains. Bridging UX collapses to "tap to confirm in your phone."

---

### 12. Bridge UX attacks — the most exploited surface in 2024

The slide deck's "Attacks on Interface" section is small but is now where the highest *frequency* of attacks happens.

#### Wallet drainers

Drained ~$494–500M in 2024 alone (67% YoY growth).
- **Inferno Drainer** controlled 40–45% of the market.
- **Pink Drainer** held 28% before announcing exit in May 2024.
- Inferno publicly "shut down" late 2023 but smart contracts kept running into 2025; Check Point Research documented 30k+ wallets drained in 6 months 2025.
- **Drainer-as-a-Service**: operator takes 20%.

#### Permit-2 phishing

`permit()` and Uniswap's Permit2 allow off-chain signatures to authorize transfers. Attackers spoof "Bridge to Base" pages that ask for a permit signature on USDC; one signed message empties the wallet.

#### `execute()` arbitrary-callData abuse

The slide deck's "Attacks on Interface (2)" example. Bridges that expose a generic `execute(target, data)` for "post-bridge actions" can be tricked by malicious frontends into routing the user's wrapped tokens through an attacker contract. The slide's `transferFrom` example is the canonical case.

#### Fake bridge frontends

Google ad keyword squatting on "Stargate finance," "Hop bridge," "Across finance" served fake URLs throughout 2024. Combined with permit phishing, devastating.

#### The Radiant pattern

Even when *signers* are audited and use hardware wallets, a malware-compromised tx-builder UI can defeat signing flows where the hardware can't parse the payload (Ledger + Gnosis Safe is the canonical bad pair). The hardware wallet displays a hash; the human cannot verify that hash matches their intent.

#### Mitigations

- Wallet-Connect 2.0 transaction simulation (Blockaid, Rabby, Wallet Guard).
- EIP-712 domain-bound signatures.
- Permit2 with strict allowance caps.
- Safe Transaction Service that *parses* the Safe blob on the hardware wallet (Ledger Tx Builder app shipped 2025).
- **EIP-7730 "structured-data display"** for hardware wallets — hardware decodes the actual semantics rather than displaying a hex blob.

---

### 13. Fast finality and pre-confirmations

A 2024–2026 push to make cross-chain UX feel "Web2-fast" by giving guarantees *before* L1 finality.

- **Espresso (HotShot consensus)** — restakes on EigenLayer; provides shared sequencing for OP-Stack and Arbitrum Orbit chains; sub-second proposer pre-confirmations + ~1–2s attester pre-confirmations.
- **Astria** — CometBFT-based universal sequencer; permissionless, VM-agnostic.
- **EigenLayer-secured pre-confirmations** — *based rollups* leverage Ethereum proposers themselves; "Based Espresso" combines Ethereum proposer pre-confs with Espresso for off-Ethereum slots.
- **Optimism Superchain interop** — same-second cross-OP-Stack messaging via shared sequencing on the Superchain; entered phased rollout 2025.

**Bridge implications.** Pre-confs let intent solvers accept user funds with seconds-level confidence rather than waiting for full Ethereum 12-min finality, reducing solver capital cost dramatically. But pre-conf safety is only as good as the slasher set — restaking slashing rules are *the* security-economics question of 2026.

---

### 14. What makes auditing bridges especially hard

Bridge audits are notoriously the highest-stakes engagements in the industry. Concrete pitfalls:

#### 14.1 Multi-chain replay
A signature valid on chain A may be reusable on chain B if the message lacks a chain-id binding. Always include `block.chainid` in EIP-712 domains; require `msg.sender == aliasedL1Sender` for L1→L2 calls.

#### 14.2 Chain-id confusion
Forked test environments sometimes leave `chainid=1`; bridges that use `chainid` as a routing key can be tricked into accepting tx replays.

#### 14.3 Fee-on-transfer / rebasing tokens
A naive `lock(amount)` followed by `mint(amount)` mints more than was actually received. Auditor's checklist: read `balanceOf` *before* and *after* the inbound transfer, mint only the delta. Stargate and Across explicitly blacklist fee-on-transfer tokens; xERC20 inherits this constraint via the lockbox.

#### 14.4 Decimal mismatch
USDC has 6 decimals on Ethereum, 18 on BSC peg-out flows. Bridges that don't normalize have minted ~10^12× too many tokens (real bug class — early 2022 Wormhole-PortalBridge near-miss). Modern NTT frameworks store a per-chain decimals table and normalize all amounts to a canonical 18-decimal representation before transit.

#### 14.5 L1 ↔ L2 address aliasing
Arbitrum aliases the sender by adding `0x1111000000000000000000000000000000001111`; Optimism uses the same offset post-Bedrock. A bridge that checks `require(msg.sender == L1_GATEWAY)` instead of `require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(L1_GATEWAY))` allows anyone to spoof L1 messages on L2. This pattern appeared in the zkSync WETH bridge audit (OpenZeppelin, 2023).

#### 14.6 Storage layout collisions in upgradeable proxies
The Wormhole near-miss (white-hat, 2022): a botched upgrade left `initialize()` callable on the new implementation, allowing arbitrary takeover. Mitigations: ERC-1967 storage slots, OpenZeppelin's `Initializable` with `_disableInitializers()` in the implementation constructor, storage gaps in upgrade-aware bases.

#### 14.7 Reentrancy via cross-chain hooks
The "executor calls user contract" pattern (LayerZero `lzReceive`, Wormhole `_completeTransferWithPayload`, CCIP `ccipReceive`) is a reentrancy vector across chains: the destination handler may re-enter the bridge's own state. Strict CEI + nonce-bumping before external calls.

#### 14.8 Source-event-only verification (the slide's communicator bug)
The slide's "only-checking-first-event-address" diagram. A verifier that relays an event but doesn't pin which contract emitted it can be tricked: attacker emits a fake `Deposit(address,uint256)` event from a self-deployed contract. Bridges using only `Topic0` matching without `address(emitter) == canonicalEscrow` checks have lost funds. **Modern audit standard:** pin emitter address into the verification scheme.

#### 14.9 Verifier-set rotation
Bridges that allow the verifier set to be rotated via a same-bridge governance message create a *bootstrapping* concern — a malicious message could rotate validators to attacker keys. Defense-in-depth: require rotation messages to come from a *separate* governance-only verifier set, with timelock and one-step social recovery.

#### 14.10 Formal verification efforts
Certora, Halmos, Hyper-Halmos rules for bridges (e.g., "for every burn on A there exists exactly one mint on B," "rate-limit invariant holds across upgrades"). LayerZero, Wormhole NTT, and CCIP all publish Certora specs. SP1 / Risc0 zkVMs are being used to *prove* light-client correctness end-to-end. K-framework verification of the Optimism `OptimismPortal` was published 2024.

---

### 15. The HTLC atomic-swap revival

The slide deck opens with HTLCs — and HTLCs largely fell out of fashion 2017–2022 because they required user-side scripting. They are quietly making a comeback in two places:

1. **Lightning↔EVM atomic swaps** via submarine swaps and PTLCs (point time-locked contracts using Schnorr/Taproot). Production: Boltz, Loop, Submarine Swaps. Allows trustless BTC↔stablecoin without a bridge.
2. **Solver-side HTLCs** — some intent bridges use HTLCs *between solvers* for cross-solver inventory rebalancing. The user signs a typed-data intent; the solvers settle among themselves using HTLCs/PTLCs in the background.

The HTLC primitive remains the *only* bridge construction with **no trusted third party in the security model** (assuming honest hashing and clock progress). Worth understanding deeply.

---

## Closing observations for students

### A. The threat model in the BDAF Bridges slide is still complete

Every 2024–2026 hack maps to one of (custodian, debt issuer, communicator, UX). The novelty since the slides is in *which* category gets exploited, not new categories.

### B. Centralization didn't lose. It evolved.

USDC/USDT chose to own their bridge layer rather than fight it. The security model of that choice is "trust the issuer once, get bridge-as-a-feature for free." Compare to Multichain ($130M evaporated when one human disappeared).

### C. Intents ate liquidity networks.

Most TVL has migrated from idle LP pools to solver inventory loops — an order-of-magnitude capital efficiency improvement. The communicator is no longer in the user's critical path.

### D. Light clients finally got cheap.

SP1, Polyhedra, Risc0 made on-chain Ethereum sync-committee verification gas-cheap. Trust-minimized bridges are no longer a research dream — they are deployed (Hashi, Telepathy, zkBridge).

### E. The hardest auditor work is now in standards composition.

A 2026 bridge protocol stitches together ERC-7683 + ERC-7281 + RIP-7212 + ERC-4337 + an ISM/DVN/RMN. The bug surface lives at the seams.

---

## Discussion questions for class

1. The slides' "decentralization spectrum of the off-chain communicator" goes from centralized → multisig → consensus → MPC → light client. Where does each of (LayerZero v2 with multi-DVN, CCIP with RMN, IBC, Across V4, Wormhole NTT, CCTP V2) sit on that spectrum, and why?

2. CCTP V2 is the *minimum-trust* USDC bridge — but you trust Circle. xERC20 with rate limits per bridge is *issuer-distributed* trust. For a stablecoin issuer, which model would you choose, and how does the answer change for a non-stable-asset issuer (e.g., a governance token)?

3. The Nomad hack ($190M) was caused by an upgrade initializing a map with `0x00`. The audited code was correct. The deployed *configuration* was not. Where in the audit workflow (slide deck §8 "Reducing your audit cost") would this be caught?

4. Across V4 has handled $20B with zero exploits using UMA optimistic settlement. Why has this construction outperformed externally-verified bridges, and what would a successful attack on Across look like?

5. The slide's "Attacks on Communicator (1) Example" shows a verifier that only checks the first event address. Construct a similar fault-pattern attack that would work against a permissionless DVN with one slow DVN and one malicious DVN under an "OR"-style aggregation.

6. The Radiant Capital hack defeated a 3-of-11 hardware-wallet multisig because the signing UI lied to the signers. What signing-flow design would have prevented this?

---

## Further reading

### Architecture deep-dives
- LayerZero v2 (DVNs) — https://medium.com/layerzero-official/layerzero-v2-explaining-dvns-02e08cce4e80
- LayerZero whitepaper — https://arxiv.org/html/2312.09118v2
- Wormhole NTT architecture — https://wormhole.com/docs/products/token-transfers/native-token-transfers/concepts/architecture/
- Wormhole Guardians — https://wormhole.com/docs/protocol/infrastructure/guardians/
- Chainlink CCIP RMN — https://blog.chain.link/ccip-risk-management-network/
- Chainlink CCT (CCIP v1.5) — https://docs.chain.link/ccip/concepts/cross-chain-token, https://blog.chain.link/ccip-v-1-5-upgrade/
- Axelar Interchain Token Service — https://docs.axelar.dev/dev/send-tokens/interchain-tokens/intro/
- Hyperlane Sovereign Consensus — https://docs.hyperlane.xyz/docs/protocol/sovereign-consensus
- Across V4 + UMA OO — https://blog.uma.xyz/articles/case-study-how-uma-secures-across-protocol
- deBridge DLN docs — https://docs.debridge.com
- IBC v2 announcement — https://ibcprotocol.dev/blog/ibc-v2-announcement
- Polyhedra zkBridge docs — https://docs.zkbridge.com
- Succinct Telepathy / SP1 — https://hackmd.io/@succinctlabs/SytMDX6Jh, https://blog.succinct.xyz/introducing-sp1/
- Polygon AggLayer pessimistic proofs — https://polygon.technology/blog/major-development-upgrade-for-a-multistack-future-pessimistic-proofs-live-on-agglayer-mainnet
- Circle CCTP V2 — https://www.circle.com/blog/cctp-v2-the-future-of-cross-chain

### Standards
- ERC-7683 — https://eips.ethereum.org/EIPS/eip-7683, https://www.erc7683.org/spec
- ERC-7281 (xERC20) — https://medium.com/@0xemkey/erc-7281-aka-xerc20-vs-erc-7683-aka-cross-chain-intents-06de500959fa
- RIP-7212 (P-256 precompile) — https://www.alchemy.com/blog/what-is-rip-7212

### Risk frameworks
- L2Beat Bridge Risk Framework forum post — https://forum.l2beat.com/t/l2bridge-risk-framework/31
- L2Beat scaling risk page — https://l2beat.com/scaling/risk
- Bridge security checklist (Zealynx) — https://www.zealynx.io/blogs/cross-chain-bridge-security-checklist
- Bridge bug tracker (community) — https://github.com/0xDatapunk/Bridge-Bug-Tracker

### Hack post-mortems (Halborn maintains canonical writeups)
- Poly Network — https://en.wikipedia.org/wiki/Poly_Network_exploit
- Wormhole — https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022
- Ronin — https://www.halborn.com/blog/post/explained-the-ronin-hack-march-2022
- Harmony Horizon — https://www.halborn.com/blog/post/explained-the-harmony-horizon-bridge-hack
- Nomad — https://www.halborn.com/blog/post/explained-the-nomad-hack-august-2022
- Multichain — https://www.halborn.com/blog/post/explained-the-multichain-hack-july-2023
- Heco — https://immunebytes.com/blog/heco-bridge-exploited-for-over-87m-in-a-suspected-private-key-leak/
- Orbit — https://www.halborn.com/blog/post/explained-the-orbit-bridge-hack-december-2023
- Radiant Capital — https://www.halborn.com/blog/post/explained-the-radiant-capital-hack-october-2024

### MEV, reorgs, finality
- Cross-chain sandwich attacks (academic) — https://arxiv.org/html/2511.15245v1
- Polygon reorgs — https://mplankton.substack.com/p/polygons-block-reorg-problem
- Solana outage history — https://www.helius.dev/blog/solana-outages-complete-history

### UX attacks
- Inferno Drainer 2025 (Check Point) — https://research.checkpoint.com/2025/inferno-drainer-reloaded-deep-dive-into-the-return-of-the-most-sophisticated-crypto-drainer/
- Drainer 2024 stats (Scam Sniffer) — https://drops.scamsniffer.io/scam-sniffer-2024-web3-phishing-attacks-wallet-drainers-drain-494-million/

### Account abstraction
- NEAR Chain Signatures — https://www.coindesk.com/tech/2024/08/08/near-pushes-signatures-on-mainnet-in-growing-trend-of-chain-abstraction
- Espresso shared sequencing — https://hackmd.io/@EspressoSystems/EspressoSequencer

### Audit-finding pattern reference
- zkSync WETH bridge audit (OpenZeppelin) — https://www.openzeppelin.com/news/zksync-weth-bridge-audit
- Address aliasing spec (Optimism) — https://github.com/ethereum-optimism/specs/issues/76
