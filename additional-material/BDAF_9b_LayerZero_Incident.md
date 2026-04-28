# LayerZero Architecture and the KelpDAO Incident — Supplementary Material

CSIC30161 Blockchain Development and Fintech | Martinet Lee

> Companion to the lecture deck *"Bridges"*. Where the bridges deck builds up the four-bucket threat model abstractly (custodian / debt issuer / communicator / interface) and the bridges supplement surveyed the modern bridge landscape, **this document zooms into one protocol — LayerZero — and one very recent incident — the KelpDAO/rsETH exploit on April 18, 2026 (~$290M)**. The case is rare and instructive: it is a *v2-era materialization* of a *v1-era architectural critique* that was raised publicly in January 2023, debated for three years, and finally manifested as a real loss ten days before this lecture.

---

## Part I: Why this case matters

Three things make the KelpDAO incident the right teaching case for this course right now.

1. **It happened 10 days ago** (April 18, 2026). The discourse is still live, with the protocol team and the OApp team publicly disagreeing about whose configuration is at fault.
2. **It is not a smart-contract bug.** The smart contracts behaved exactly as written. The exploit targeted **off-chain RPC infrastructure** — the very layer the slide deck calls "the off-chain communicator." It is a textbook execution of the slide's *Attacks on Communicator* tree.
3. **It validates a 2023 architectural critique.** The L2BEAT and James Prestwich critiques of LayerZero v1 in January 2023 argued that LayerZero's "Oracle + Relayer = independent" claim collapsed under default-config conditions to "trust LayerZero Labs." LayerZero shipped v2 in 2024 with a new DVN model that *partially* addresses this. The KelpDAO incident demonstrates that the fix was incomplete in practice, not just in theory.

> The lesson is **not** that LayerZero is uniquely insecure. The lesson is that *configurable security only protects you if you configure it,* and the default rarely buys you the diversity the marketing implies.

---

## Part II: LayerZero v1 architecture

### The Endpoint contract

Each chain LayerZero supports has an immutable `Endpoint` contract (`LayerZero-Labs/LayerZero-v1/contracts/Endpoint.sol`). User Applications (UAs) — the OApps in v1's vocabulary — interact with it via two functions:

```solidity
// Source side
endpoint.send(
    uint16 _dstChainId,
    bytes  _destination,        // remote OApp address
    bytes  _payload,
    address payable _refundAddr,
    address _zroPaymentAddress,
    bytes _adapterParams        // gas + airdrop on dst
);

// Destination side — the OApp implements this callback
function lzReceive(
    uint16 _srcChainId,
    bytes  _srcAddress,
    uint64 _nonce,
    bytes  _payload
) external;
```

The base helpers `LzApp` and `NonblockingLzApp` in `LayerZero-Labs/solidity-examples` give OApps a standard inheritance pattern. **Most OApps inherit `NonblockingLzApp`**, which catches reverts in the inner `_blockingLzReceive` so a single failing message does not stall the per-channel queue. (The channel-blocking pattern was a recurring audit finding — see the Tapioca Code4rena contest in §VI.)

### The Ultra Light Node and the Oracle/Relayer split

Behind the Endpoint sits the **Ultra Light Node (`UltraLightNodeV2`)**. Verification was deliberately split between two off-chain workers:

```
        Source Chain                                      Destination Chain
   ┌──────────────────┐                              ┌────────────────────────┐
   │  Endpoint.send() │                              │     Endpoint           │
   │      ↓           │                              │        ↓               │
   │  emit Packet     │                              │  UltraLightNodeV2      │
   └──────────────────┘                              │  validateProof(...)    │
            │                                        └────────────────────────┘
            │                                                ▲           ▲
            │                                                │           │
            │           OFF-CHAIN WORKERS                    │           │
            │    ┌───────────────────────────┐               │           │
            └───►│ Oracle: ships block hash  ├──updateHash───┘           │
                 └───────────────────────────┘                           │
                 ┌───────────────────────────┐                           │
                 │ Relayer: ships tx proof   ├──validateTransactionProof─┘
                 └───────────────────────────┘
```

The intended security argument: a forged message requires both a wrong block hash *and* a wrong transaction proof. **As long as Oracle and Relayer are independent parties, collusion is required.** That assumption is the whole load-bearing claim of v1's security story.

### Application-controllable configuration

UAs can override the default off-chain workers via `ILayerZeroUserApplicationConfig`:

| Function | Effect |
|---|---|
| `setConfig(version, chainId, configType, config)` | Pin Oracle, Relayer, gas, inbound block confirmations, outbound proof type, MessageLib version |
| `setSendVersion(uint16)` | Pick which MessageLib to use when sending |
| `setReceiveVersion(uint16)` | Pick which MessageLib to use when receiving |
| `forceResumeReceive(srcChainId, srcAddress)` | Clear a stuck head-of-queue payload |

If a UA never calls `setConfig` and never pins a receive version, the Endpoint **falls back to the default config**, which the LayerZero Labs multisig controls. This default-fallback path is the focus of the 2023 critique below.

### Pre-Crime

A LayerZero-Labs off-chain harness ([Pre-Crime announcement](https://medium.com/layerzero-official/introducing-pre-crime-49bef4a581d5)). The relayer forks the destination chain locally, replays the inbound packet, and asserts UA-supplied invariants (e.g., total OFT supply across all chains must equal pre-call supply). If invariants fail, **the relayer refuses to deliver.** Pre-Crime is a delivery-time veto, not an on-chain check — useful, but not a substitute for on-chain verification.

---

## Part III: The 2023 critique — L2BEAT and James Prestwich

### The L2BEAT experiment (January 5, 2023)

L2BEAT — co-founded by Bartek Kiepuszewski; the experimental write-up bylined to Krzysztof Urbański — published *Circumventing Layer Zero: Why Isolated Security is No Security* ([L2BEAT Medium](https://medium.com/l2beat/circumventing-layer-zero-5e9f652a5d3e)).

L2BEAT deployed a token called "CarpetMoon" on Ethereum and Optimism using **the default LayerZero config**. They then reconfigured Oracle and Relayer to attacker-controlled addresses and drained the escrow. The experimental setup proved: under default config, *anyone with control of the default Oracle and Relayer can rewrite cross-chain history at will*.

### James Prestwich's "ZeroValidation" (January 30, 2023)

The harder-hitting follow-up was [Prestwich's *ZeroValidation* post](https://prestwich.substack.com/p/zero-validation). The verified technical claims:

1. The Endpoint and `UltraLightNodeV2` were owned by a **2-of-5 LayerZero MultiSig**.
2. **Crit 1 — Default Receiving Library.** Any application that has not called `setReceiveVersion` is at the mercy of `setDefaultReceiveVersion`. The multisig can install a malicious receive library, push it as the default, and inject arbitrary messages **without Oracle/Relayer signoff**. This is *not* a collusion problem — it is a single-multisig power.
3. **Crit 2 — Proof-Validation Library.** Even with a non-default receive library, the multisig could substitute the proof-validation library (`FPValidator` / `MerklePatriciaTrie`) inside `UltraLightNodeV2` and modify message payloads after Oracle and Relayer have signed.
4. **Stargate's then-current state:** *"Stargate currently does not have a receive library set. It is therefore vulnerable to Crit 1. Stargate currently does not have a proof validation library set for any chainid."*
5. Prestwich documented two existing special-case proof-modification functions hard-coded into the ULN — `_secureStgTokenPayload` and `_secureStgPayload` — which silently rewrote Stargate payloads. **Live evidence that this power had already been exercised.**

The collusion problem (one team running both default workers) and the multisig-can-rewrite-defaults problem are two distinct trust paths to the same outcome: *under default config, Stargate and most v1 UAs collapsed to trusting LayerZero Labs.*

### LayerZero's response

[LayerZero Labs' Twitter rebuttal](https://x.com/LayerZero_Core/status/1611070058972999680): *"This is both flawed and also ignores the fact that every single bridge hack of the past few years come from a shared security model."* Bryan Pellegrino (CEO) and Ryan Zarick (CTO) argued in interviews and on X:

- LayerZero is a *protocol*, not an opinionated security service. Apps choose their config.
- Default-config power is documented in the whitepaper, not a hidden backdoor.
- Stargate's DAO had already voted on January 3, 2023, to migrate Stargate off the default library to a custom one.
- Their framing piece: ["Sovereignty Over Your Application's Security Matters"](https://medium.com/layerzero-ecosystem/sovereignty-over-security-matters-077a2eb5cf75).

For full timeline coverage, see Arjun Chand's [*L2BEAT vs. LayerZero: The Debate*](https://lifi.substack.com/p/l2beat-vs-layerzero-the-debate). L2BEAT to this day flags every LayerZero-using bridge with the disclaimer *"funds can be stolen if oracles and relayers collude"* and that security depends on the application's config.

> **Connect to the slide deck:** The slide *"The Decentralization of Bridges"* lists the spectrum — centralized → multisig → consensus → MPC → light client. The 2023 critique was effectively saying: "you advertise the spectrum, but in practice almost every UA sits at the leftmost position because of how default config works." The DVN model in v2 is the architectural response to that critique.

---

## Part IV: LayerZero v2 architecture

LayerZero v2 mainnet shipped in early 2024 ([announcement](https://medium.com/layerzero-official/introducing-layerzero-v2-076a9b3cb029)). Three changes matter.

### 1. The Endpoint becomes immutable

> "Once implemented, no entity can change endpoints as they are immutable and non-upgradeable." (LayerZero v2 docs)

The Endpoint's job shrinks to: a pure message channel offering exactly-once and lossless delivery, nonce ordering, and library lookup. It cannot be upgraded, paused, or reconfigured.

### 2. The MessageLib registry is append-only

New libraries can be **added**. Existing ones **can never be removed or upgraded in place**. The default library is `Ultra-Light Node 302` (`ULN302`) — feature-parity with the v1 ULN but redesigned around the DVN model.

This directly addresses Prestwich's Crit 1: *if an OApp pins `ULN302`, no one — including LayerZero Labs — can swap it out from underneath them.* The "library-rug" branch of the 2023 critique is structurally closed in v2.

### 3. Oracle + Relayer → DVNs + Executors

```
                  ┌─────────────────────────────────────────────┐
                  │          OApp Security Stack                │
                  │   requiredDVNs[]   optionalDVNs[]   thresh  │
                  └─────────────────────────────────────────────┘
                              │             │             │
       ┌─────────────┬────────┴─────────────┴─────────────┴─────┐
       ▼             ▼                                          ▼
  ┌─────────┐   ┌─────────┐    ...   ┌─────────────┐      ┌─────────────┐
  │  DVN A  │   │  DVN B  │          │   DVN C     │      │   Executor  │
  │ (req)   │   │ (req)   │          │ (optional)  │      │  (delivery) │
  └─────────┘   └─────────┘          └─────────────┘      └─────────────┘
       │             │                       │                    │
       └─────────────┴───── attest ──────────┘                    │
                          │                                       │
                          ▼                                       ▼
                ┌─────────────────────────────┐         ┌────────────────┐
                │     ReceiveUln302           │◄────────│ Endpoint.lzRcv │
                │   commitVerification(...)   │         │   (delivery)   │
                └─────────────────────────────┘         └────────────────┘
```

Key facts:

- **DVN (Decentralized Verifier Network).** Each DVN independently watches the source chain, computes the payload hash for a packet, and writes its attestation to the destination's `ReceiveUln302`.
- **X-of-Y-of-N formula.** A packet is verified only when *all* required DVNs (X) have attested **and** *at least the threshold* (Y) of the optional set (N) have attested. Canonical example from LayerZero docs: "2 of 3 of 5" — 2 required, 3-of-5 optional.
- **Executor — separated from verification.** Once verification completes, an Executor (any party) calls the destination Endpoint to invoke `lzReceive` with appropriate gas. Critically, **an Executor cannot bypass verification.** Its role is purely delivery and gas accounting.
- **OApp configuration.** Configured per-pathway (`oapp`, `dstEid`):
  - `EndpointV2.setSendLibrary(oapp, dstEid, newLib)`
  - `EndpointV2.setReceiveLibrary(oapp, dstEid, newLib, gracePeriod)`
  - `EndpointV2.setReceiveLibraryTimeout(oapp, dstEid, lib, gracePeriod)` — cooldown for migration.
- **DVN config is also per-pathway**, with independent `requiredDVNs[]`, `optionalDVNs[]`, `optionalDVNThreshold`.

### Notable DVN operators (2025–2026)

Confirmed via [LayerZero v2 deployments docs](https://docs.layerzero.network/v2/deployments/dvn-addresses), Mark Murdock's [*Explaining DVNs*](https://medium.com/layerzero-official/layerzero-v2-explaining-dvns-02e08cce4e80), and primary integration posts:

- **LayerZero Labs DVN** (the team's own; uses a 2-of-3 internal multisig to sign attestations)
- **Google Cloud**
- **Polyhedra zkLightClient / zkBridge** (ZK-proof-based)
- **Nethermind** (multi-AZ, load-balanced)
- **Animoca Brands**
- **Blockdaemon**
- **Switchboard**
- **Gitcoin, P2P, StableLab, Delegate, Tapioca** (testnet-launch set)
- **EigenLayer cryptoeconomic DVN framework** ([*The Cryptoeconomic DVN Framework*](https://medium.com/layerzero-official/layerzero-x-eigenlayer-the-cryptoeconomic-dvn-framework-68af27ca2040)) — adds AVS-style slashing.

### What did NOT change in v2

- **The default DVN configuration is `LayerZero Labs DVN + Google Cloud DVN`.** That is two organizations — better than v1's one-organization fallback — but it is *not* the X-of-Y-of-N pluralism the marketing implies.
- An OApp that deploys with no `setConfig` calls is verified by exactly two parties, one of which is LayerZero Labs.
- For chains with limited DVN coverage at launch (think: a brand-new L2), the LayerZero quickstart effectively encourages a 1-of-1 LayerZero-Labs setup — which is what KelpDAO appears to have used on Unichain.

> **The Prestwich Crit 1 (library-rug) branch is structurally closed in v2. The "Oracle and Relayer are the same team" branch is partially closed by adding Google Cloud as a default co-signer, but still requires the OApp deployer's diligence to actually pluralize. The KelpDAO incident is the demonstration of what happens when that diligence is absent.**

---

## Part V: The KelpDAO/rsETH Incident — April 18, 2026

### The facts

| Item | Detail |
|---|---|
| **Date** | April 18, 2026 |
| **Loss** | ~116,500 rsETH, ~$290–293M at the time |
| **Mechanism** | Forged cross-chain message minted rsETH on Ethereum without a corresponding burn on Unichain |
| **DVN configuration** | **1-of-1: LayerZero Labs DVN as sole verifier** |
| **Attribution** | Lazarus Group / DPRK (TraderTraitor sub-cluster) |
| **Second-stage blocked** | An additional ~40,000 rsETH (~$95M) prevented when KelpDAO paused contracts |
| **Funds frozen** | Arbitrum Security Council froze 30,766 ETH of attacker proceeds on April 20, 2026 |

### The attack chain

```
Step 1   Lazarus compromises 2 of LayerZero Labs' INTERNAL RPC nodes
         (binary-swap supply-chain compromise on the node stack)

Step 2   Lazarus DDoS's the EXTERNAL public RPC nodes that the
         LayerZero Labs DVN consults as backup truth source

Step 3   With external RPCs unreachable, the LayerZero Labs DVN
         falls back to the poisoned internal RPC nodes

Step 4   The poisoned RPC nodes report a fake `Burn` event on Unichain
         claiming the attacker burned rsETH (they did not)

Step 5   The LayerZero Labs DVN — the SOLE required DVN on KelpDAO's
         Unichain pathway — signs an attestation for the fake event

Step 6   ReceiveUln302.commitVerification() finalizes the attestation
         (no other DVN exists to disagree)

Step 7   Executor delivers lzReceive() on Ethereum

Step 8   rsETH OFT contract on Ethereum mints 116,500 rsETH to the
         attacker (because the inbound packet says "burn happened")
```

The smart contracts behaved exactly as written. The **off-chain communicator** was the failure point. This is a precise execution of the *Attacks on Communicator (1)* slide ("trick the communicator into forwarding invalid messages") combined with the *Attacks on Communicator (2)* slide ("change the truth of the data source") — the truth source was the RPC layer, and Lazarus changed it.

### The blame fight

**LayerZero's position** ([*KelpDAO Incident Statement*](https://layerzero.network/blog/kelpdao-incident-statement)):

> "LayerZero and other external parties previously communicated best practices around DVN diversification to KelpDAO. Despite these recommendations, KelpDAO chose to utilize a 1/1 DVN configuration."

LayerZero also asserted: "There is zero contagion to any other cross-chain assets or applications" — pointing to the modular security model as having contained the blast radius.

**KelpDAO's rebuttal** ([CoinDesk coverage](https://www.coindesk.com/tech/2026/04/20/kelp-dao-claims-layerzero-s-default-settings-are-what-actually-caused-the-usd290-million-disaster); [Crypto.news](https://crypto.news/kelp-dao-blames-layerzero-defaults-for-290m-rseth-bridge-disaster/)):

> They "implemented LayerZero's own public code and defaults across multiple networks" and the compromised DVN "was operated by LayerZero itself."

I.e.: this was LayerZero's RPC stack, LayerZero's DVN, and the configuration that LayerZero's own quickstart effectively recommends for new chains.

**The community read** ([NewsBTC](https://www.newsbtc.com/news/crypto-community-slams-layerzero-kelpdao-290m-hack/)):

> The dominant critique is structural — that as long as v2 "defaults" still resolve to "LayerZero Labs DVN," the Prestwich/L2BEAT-2023 critique was never substantively retired, just rebranded.

### Why this is the right teaching case

Look at the slide deck's threat tree:

| Slide concept | KelpDAO's manifestation |
|---|---|
| Attacks on Custodian (1): take over privileged addresses | Not used |
| Attacks on Custodian (2): craft proofs that pass verification | Not used |
| Attacks on Custodian (3): fake deposit events | **Used** — fake `Burn` event on source chain |
| Attacks on Debt Issuer | The destination contract minted as designed; no signature bypass needed |
| Attacks on Communicator (1): trick into forwarding invalid messages | **Used** — DVN forwarded poisoned RPC data |
| Attacks on Communicator (2): change the truth of the data source | **Used** — RPC compromise + DDoS forced fall-back to malicious nodes |
| Attacks on Interface | Not used |

The incident exercises **three** of the four buckets simultaneously, and the cause of the cascade is the **single-DVN configuration** — the absence of *plural truth sources*, which is the entire reason the X-of-Y-of-N formula exists.

> **The slide deck's framing is vindicated, not invalidated.** What the BDAF deck calls "the off-chain communicator that determines whether a bridge protocol is decentralized or not" turned out to be the exact failure point.

---

## Part VI: Things that are NOT LayerZero exploits (clarification)

A common pedagogical mistake is to lump LayerZero-using protocols' exploits into "LayerZero hacks." They are not. Specifically:

### Sonne Finance, May 15, 2024, ~$20M — NOT LayerZero
A Compound-v2-fork "donation attack" on Optimism. Attacker exploited a market-initialization race + flash-loaned VELO to inflate exchange rate. LayerZero played no role. ([Halborn explainer](https://www.halborn.com/blog/post/explained-the-sonne-finance-hack-may-2024)).

### TapiocaDAO, July–August 2023 — Code4rena audit, not an exploit
Surfaced ~60 unique HIGH-severity issues. Several were **OApp integration bugs** — most notably channel-blocking via gas griefing ([issue #1207](https://github.com/code-423n4/2023-07-tapioca-findings/issues/1207), [issue #1220](https://github.com/code-423n4/2023-07-tapioca-findings/issues/1220)) — but these are arguments about how an OApp must use `NonblockingLzApp` and set min-gas, not about LayerZero protocol bugs.

### Radiant Capital — two separate 2024 incidents, both unrelated to LayerZero
- **January 2, 2024, ~$4.5M** — Compound-v2-fork rounding/precision flash-loan attack on Arbitrum, on a freshly launched USDC market with `totalSupply == 0`. No cross-chain involvement.
- **October 16, 2024, ~$53M** — Lazarus malware (INLETDRIFT) compromised three developer macOS devices and altered the Safe{Wallet} front-end so signers approved malicious `transferOwnership()` while seeing legitimate transactions. **LayerZero infrastructure was untouched.** This is a signer-device compromise, not a bridge compromise.

If anything, these cases support the slide deck's *defense-in-depth* argument: even apps that consume LayerZero correctly can die to operational-security failures the bridge layer cannot prevent.

---

## Part VII: Public LayerZero v2 audit landscape

For students who want to understand the audit posture: LayerZero maintains [`LayerZero-Labs/Audits`](https://github.com/LayerZero-Labs/Audits). v2-era reports include:

**EndpointV2 (December 2023):** Blockian, CMichel, **Certora (formal verification)**, OtterSec, Paladin, Windhustler, **Zellic**.

**EndpointV2Alt (February 2026):** OtterSec, Paladin.

**DVN audits:** OtterSec (Sept 2023), Paladin (Aug 2023), Zellic (Aug 2023, March 2024), plus an EigenLayer-DVN audit subfolder.

**OApp / OFT (EVM):** [ChainSecurity (Jan 2024)](https://www.chainsecurity.com/security-audit/layerzero-oft-oapp), [Zellic (Jun 2024)](https://reports.zellic.io/publications/layerzero-oapp--oft), Hexens (Nov 2024 Upgradeable variant), Zellic (Sept 2025).

**Public Code4rena contests:** [Sui Endpoint V2 ($103k pool, Sept 17–30, 2025)](https://code4rena.com/audits/2025-09-layerzero-endpoint-v2-sui), [Starknet Endpoint (Oct 2025)](https://code4rena.com/audits/2025-10-layerzero-starknet-endpoint), [Stellar Endpoint (April 2026)](https://code4rena.com/audits/2026-04-layerzero-stellar-endpoint).

The point for students is *not* that all these audits prevented the KelpDAO incident — they couldn't have. **No amount of code audit catches a poisoned RPC supply chain feeding a DVN.** That layer is governed by operational security and DVN diversity, not Solidity review.

---

## Part VIII: Lessons

### A. "Configurable security" is only as strong as the configuration

LayerZero v2's modular DVN architecture *can* deliver excellent security. It also *can* deliver 1-of-1 LayerZero-Labs verification on a fresh chain. The protocol does not enforce a minimum security posture. **For OApp deployers, this is a security responsibility — not a security guarantee.**

### B. Defaults matter more than marketing

Stargate v2 (the LayerZero team's flagship OApp) currently runs **2-of-2 required: Nethermind + LayerZero Labs** on Ethereum routes, with a Stargate DAO proposal to add Predicate as a third for **3-of-3** ([Stargate forum](https://stargate.discourse.group/t/predicate-dvn-added-to-stargates-dvn-set/591)). That is plausible production configuration. It is not the LayerZero quickstart default. The gap between "what the team's own flagship OApp uses" and "what a new deployer gets out of the box" is the gap that ate KelpDAO.

### C. Off-chain infrastructure is in scope

A DVN is a smart contract attestation backed by an off-chain process. The off-chain process reads RPC. If RPC is poisoned, the attestation is poisoned. **Auditing a bridge's smart contracts does not audit the operational security of its DVN operators.** This is the most important infra-level lesson the lecture can deliver.

### D. The L2BEAT critique was substantively right

The 2023 critique said: *the security spectrum LayerZero advertises collapses to "trust LayerZero Labs" under default-config conditions.* LayerZero responded: *configure your own security.* Three years later, an OApp that did not configure its own security lost $290M. The critique was substantive, not pedantic.

### E. OFT ≠ ERC-7281

An easy student error: assuming LayerZero's **OFT (Omnichain Fungible Token)** standard is the same as Connext-pushed **ERC-7281 (xERC20)**. They are competing designs:

| | OFT (LayerZero) | ERC-7281 / xERC20 (Connext et al.) |
|---|---|---|
| Bridge logic | Bundled into the token | External; token is bridge-agnostic |
| Per-bridge mint limits | No on-chain enforcement | Yes — issuer rate-limits each bridge |
| Vendor lock-in | LayerZero | None |
| Burn-and-mint | Yes | Yes |

OFT is operationally simpler; ERC-7281 contains blast radius better. They are not interchangeable.

---

## Discussion questions

1. **The slide-deck question, revisited.** The slide deck argues that the *off-chain communicator* determines whether a bridge protocol is decentralized. Where does LayerZero v2 sit on the centralized → multisig → consensus → MPC → light client spectrum, given that the *application* picks its DVN set? Is the spectrum still meaningful per-protocol, or only per-OApp now?

2. **Default vs. explicit.** Suppose you are deploying a new OApp on a brand-new chain (Unichain at launch, say). Only the LayerZero Labs DVN supports that chain on day one. What is the right deployment posture: launch with 1-of-1 and pluralize later, or wait for two DVNs and miss the launch window? Argue both sides.

3. **Auditor's scope.** Imagine you are auditing KelpDAO's rsETH OApp two weeks before the April 2026 incident. The smart contracts are clean. The DVN config is 1-of-1 LayerZero Labs. Is this an audit finding? What severity? How does the slide deck's framing of "audit scope is what the project defines" interact with your answer?

4. **Trust composition.** If an OApp uses 3-of-5 DVNs from {LayerZero Labs, Google Cloud, Polyhedra, Nethermind, Animoca}, what are the trust assumptions? Construct an attack that requires compromising **only two** of these — i.e., where the X-of-Y-of-N argument fails for non-cryptographic reasons.

5. **Pre-Crime.** LayerZero v1's Pre-Crime simulation forks the destination chain and asserts UA-supplied invariants before delivery. Would a Pre-Crime check have prevented the KelpDAO mint? Why or why not? What invariant would you have written?

6. **Cross-deck connection.** In the audit lecture (BDAF #8) we argued that "the auditor's thought process must include the toolchain underneath the source." Apply that argument to bridge audits: what is the analogous "toolchain underneath" for a DVN-based bridge, and how would you scope an engagement to cover it?

---

## Further reading

### LayerZero primary sources
- LayerZero v1 Endpoint contract — https://github.com/LayerZero-Labs/LayerZero-v1/blob/main/contracts/Endpoint.sol
- LayerZero v1 docs (Endpoint, custom config) — https://docs.layerzero.network/v1/home/concepts/layerzero-endpoint, https://docs.layerzero.network/v1/developers/evm/evm-guides/ua-custom-configuration/overview
- Pre-Crime announcement — https://medium.com/layerzero-official/introducing-pre-crime-49bef4a581d5
- LayerZero v2 announcement — https://medium.com/layerzero-official/introducing-layerzero-v2-076a9b3cb029
- LayerZero v2 docs (Endpoint, MessageLib, Security Stack) — https://docs.layerzero.network/v2/concepts/v2-overview, https://docs.layerzero.network/v2/concepts/protocol/message-library, https://docs.layerzero.network/v2/concepts/modular-security/security-stack-dvns
- Default config docs — https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config
- DVN explainer — https://medium.com/layerzero-official/layerzero-v2-explaining-dvns-02e08cce4e80
- DVN deployment list — https://docs.layerzero.network/v2/deployments/dvn-addresses
- v2 GitHub — https://github.com/LayerZero-Labs/LayerZero-v2

### The 2023 critique
- L2BEAT — *Circumventing Layer Zero* — https://medium.com/l2beat/circumventing-layer-zero-5e9f652a5d3e
- L2BEAT Twitter announcement — https://x.com/l2beat/status/1611008135086411779
- James Prestwich — *ZeroValidation* — https://prestwich.substack.com/p/zero-validation
- LayerZero rebuttal thread — https://x.com/LayerZero_Core/status/1611070058972999680
- *Sovereignty Over Your Application's Security Matters* — https://medium.com/layerzero-ecosystem/sovereignty-over-security-matters-077a2eb5cf75
- The Block coverage — https://www.theblock.co/post/206770/layerzero-ceo-denies-accusations-of-critical-trusted-third-party-vulnerabilities
- CoinDesk — *Bridge Platform LayerZero Denies Allegations It Kept 'Backdoor' Secret* — https://www.coindesk.com/tech/2023/01/30/bridge-platform-layerzero-denies-allegations-it-kept-backdoor-secret
- Arjun Chand — *L2BEAT vs. LayerZero: The Debate* — https://lifi.substack.com/p/l2beat-vs-layerzero-the-debate
- L2BEAT bridge listings — https://l2beat.com/bridges/projects/stargate, https://l2beat.com/bridges/projects/stargatev2, https://l2beat.com/bridges/projects/layerzerov2oft

### KelpDAO incident (April 2026)
- LayerZero — *KelpDAO Incident Statement* — https://layerzero.network/blog/kelpdao-incident-statement
- Chainalysis — *Inside the KelpDAO Bridge Exploit* — https://www.chainalysis.com/blog/kelpdao-bridge-exploit-april-2026/
- CoinDesk — LayerZero blames Kelp — https://www.coindesk.com/tech/2026/04/20/layerzero-blames-kelp-s-setup-for-usd290-million-exploit-attributes-it-to-north-korea-s-lazarus
- CoinDesk — KelpDAO blames LayerZero defaults — https://www.coindesk.com/tech/2026/04/20/kelp-dao-claims-layerzero-s-default-settings-are-what-actually-caused-the-usd290-million-disaster
- Crypto.news — https://crypto.news/kelp-dao-blames-layerzero-defaults-for-290m-rseth-bridge-disaster/
- The Defiant — https://thedefiant.io/news/hacks/lazarus-kelpdao-290m-layerzero-rpc-hack-da50p3
- NewsBTC community reaction — https://www.newsbtc.com/news/crypto-community-slams-layerzero-kelpdao-290m-hack/

### Audit posture
- LayerZero-Labs/Audits — https://github.com/LayerZero-Labs/Audits
- Zellic OApp & OFT report — https://reports.zellic.io/publications/layerzero-oapp--oft
- ChainSecurity OFT/OApp report — https://www.chainsecurity.com/security-audit/layerzero-oft-oapp
- Code4rena Sui Endpoint V2 contest — https://code4rena.com/audits/2025-09-layerzero-endpoint-v2-sui

### Confused-with-LayerZero post-mortems (for clarification)
- Sonne Finance — https://medium.com/@SonneFinance/post-mortem-sonne-finance-exploit-12f3daa82b06
- Tapioca Code4rena report — https://code4rena.com/reports/2023-07-tapioca
- Radiant Capital October 2024 — https://medium.com/@RadiantCapital/radiant-post-mortem-fecd6cd38081

### OFT standard and ERC-7281
- OFT Standard — https://docs.layerzero.network/v2/home/token-standards/oft-standard
- ERC-7281 (xERC20) discussion — https://medium.com/@0xemkey/erc-7281-aka-xerc20-vs-erc-7683-aka-cross-chain-intents-06de500959fa
- OFT exposure-risk analysis (Llama Risk) — https://www.llamarisk.com/research/layerzero-oft-standard-defi-exposure-risk
