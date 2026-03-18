# BDaF 2026 Lab04 — Membership Board: Storage vs. Merkle Trees

**Deadline:** Mar 27st (Friday midnight 23:59)

**Submission:**

---

# Readings

### Merkle Trees
- https://opendsa-server.cs.vt.edu/ODSA/Books/usek/gin231-c/spring-2022-39903ab6-41ba-4bfb-9a68-5abc9010a363/TR_930am/html/MerkleTrees.html
- https://decentralizedthoughts.github.io/2020-12-22-what-is-a-merkle-tree/

### OpenZeppelin Merkle Proof
- https://docs.openzeppelin.com/contracts/5.x/api/utils#MerkleProof

### Solidity Gas Optimization
- https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
- https://www.evm.codes/

### Gas Profiling
- Hardhat Gas Reporter: https://github.com/cgewecke/hardhat-gas-reporter
- Foundry Gas Reports: https://book.getfoundry.sh/forge/gas-reports

---

# Project Overview

In this lab, you will build a **Membership Board** contract where an admin manages a list of **1,000 members**. You will implement membership management using three different approaches and compare their gas costs.

The goal of this assignment is to help you understand:

- how on-chain storage costs scale with the number of entries
- the trade-off between on-chain storage (mapping) and off-chain computation (Merkle proofs)
- how batching operations can reduce per-unit gas costs
- how to use gas profiling tools to measure and compare contract execution costs

### Learning Objectives

- Understand the gas cost of `SSTORE` and `SLOAD` operations
- Compare storage-based membership (mapping) vs. commitment-based membership (Merkle tree)
- Learn to use gas profiling tools (Hardhat Gas Reporter or Foundry gas reports)
- Reason about trade-offs: on-chain storage cost vs. off-chain proof generation

---

# Setup

We provide a pre-generated list of **1,000 Ethereum addresses** in [`members.json`](./members.json). You **must use this list** for your assignment so that results are comparable across submissions.

We also provide a script [`generate_members.js`](./generate_members.js) that can generate a fresh list of N addresses if you want to experiment with different sizes:

```bash
node generate_members.js <N>
```

This outputs a `members.json` file with the generated addresses. Requires `ethers` (`npm install ethers`).
The same list must be used across all three approaches while doing gas profiling for different sizes.

You must also generate the **Merkle tree** and **Merkle proofs** off-chain (in your test/script files) for use in Part 3.

> **Hint:** Use the [`@openzeppelin/merkle-tree`](https://github.com/OpenZeppelin/merkle-tree) JavaScript library or [`murky`](https://github.com/dmfxyz/murky) (for Foundry) to generate the tree and proofs off-chain.

---

# Contract Requirements

Create a single contract called `MembershipBoard` with the following functionality.

---

## Part 1: Add Members One-by-One (Mapping)

Implement a function that adds **one member at a time** using a key-value mapping:

```solidity
mapping(address => bool) public members;

function addMember(address _member) external onlyOwner
```

Requirements:
- Only the contract owner can call this function
- Must store the member in the `members` mapping
- Must revert if the address is already a member
- Must emit a `MemberAdded(address indexed member)` event

To register all 1,000 members, this function must be called **1,000 times**.

---

## Part 2: Batch Add Members (Mapping)

Implement a function that adds **multiple members at once** using the same mapping:

```solidity
function batchAddMembers(address[] calldata _members) external onlyOwner
```

Requirements:
- Only the contract owner can call this function
- Must store each member in the `members` mapping
- Must revert if any address is already a member
- Must emit a `MemberAdded(address indexed member)` event for each member

> **Note:** You may need to split the 1,000 members into multiple batches depending on the block gas limit. Record how many batches you used and the size of each batch.

---

## Part 3: Set Merkle Root

Implement a function that stores a **Merkle root** representing the membership list:

```solidity
bytes32 public merkleRoot;

function setMerkleRoot(bytes32 _root) external onlyOwner
```

Requirements:
- Only the contract owner can call this function
- Must update the `merkleRoot` state variable
- Must emit a `MerkleRootSet(bytes32 indexed root)` event

The Merkle tree should be constructed off-chain from the same list of 1,000 addresses. The leaf for each address should be:

```solidity
leaf = keccak256(abi.encodePacked(address))
```

> **Hint (OpenZeppelin Merkle Tree library):** If you use the `@openzeppelin/merkle-tree` library, use `StandardMerkleTree.of(values, leafEncoding)` where each value is `[address]` and the leaf encoding is `["address"]`. The library handles double-hashing internally, so your contract verification should use `MerkleProof.verify()` from OpenZeppelin which is compatible with this format.

---

## Part 4: Verify Membership (Mapping)

Implement a function that checks membership using the mapping:

```solidity
function verifyMemberByMapping(address _member) external view returns (bool)
```

Requirements:
- Returns `true` if the address exists in the `members` mapping
- Returns `false` otherwise

---

## Part 5: Verify Membership (Merkle Proof)

Implement a function that checks membership using a Merkle proof:

```solidity
function verifyMemberByProof(address _member, bytes32[] calldata _proof) external view returns (bool)
```

Requirements:
- Computes the leaf hash from the address
- Verifies the proof against the stored `merkleRoot`
- Returns `true` if the proof is valid, `false` otherwise

> **Hint:** Use OpenZeppelin's `MerkleProof.verify()`:
> ```solidity
> import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
>
> bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_member))));
> return MerkleProof.verify(_proof, merkleRoot, leaf);
> ```
> Note: The double `keccak256` is required when using OpenZeppelin's `StandardMerkleTree` to prevent second preimage attacks.

---

# Gas Profiling

This is the **core analysis** of this lab.

You must measure and record the gas usage of the following **5 actions**:

| # | Action | Description |
|---|--------|-------------|
| 1 | `addMember` | Gas cost of adding **one** member via `addMember()`. Report the gas for a single call. To register all 1,000 members, multiply by 1,000 (also account for the 21,000 base transaction cost per call). |
| 2 | `batchAddMembers` | Total gas cost of adding **all 1,000 members** via `batchAddMembers()`. If you split into multiple batches, report the total across all batches. |
| 3 | `setMerkleRoot` | Gas cost of calling `setMerkleRoot()` once to register all 1,000 members. |
| 4 | `verifyMemberByMapping` | Gas cost of verifying **one** member using the mapping. |
| 5 | `verifyMemberByProof` | Gas cost of verifying **one** member using a Merkle proof. |

### How to Measure Gas

Use one of the following tools:

**Hardhat Gas Reporter** (recommended for Hardhat users):
```bash
npm install --save-dev hardhat-gas-reporter
```

Add to `hardhat.config.js`:
```javascript
require("hardhat-gas-reporter");

module.exports = {
  gasReporter: {
    enabled: true,
  },
};
```

**Foundry Gas Reports** (recommended for Foundry users):
```bash
forge test --gas-report
```

You may also use `gasleft()` in Solidity or `tx.receipt.gasUsed` in your test scripts for more granular measurements.

---

# Questions

Answer the following questions in your `README.md`:

1. **Storage cost comparison:** What is the total gas cost of registering all 1,000 members for each of the three approaches (addMember x1000, batchAddMembers, setMerkleRoot)? Which is cheapest and why?

2. **Verification cost comparison:** What is the gas cost of verifying a single member using the mapping vs. the Merkle proof? Which is cheaper and why?

3. **Trade-off analysis:** The Merkle tree approach is very cheap to store on-chain but requires the verifier to provide a proof. In what scenarios would you prefer the mapping approach over the Merkle tree approach, and vice versa? Consider factors such as:
   - Who pays for the verification gas?
   - How often does the membership list change?
   - Is the full member list public or private?

4. **Batch size experimentation:** Try different batch sizes for `batchAddMembers` (e.g., 50, 100, 250, 500). How does the per-member gas cost change with batch size? Is there a sweet spot?

---

# Project Requirements

- Project MUST use **Hardhat or Foundry**
- Tests must be included
- TA must be able to run tests via:

```
npx hardhat test
```

or

```
forge test
```

---

# Minimum Test Cases

## Adding Members

- Owner can add a single member via `addMember`
- Non-owner cannot add a member
- Adding a duplicate member reverts
- Owner can batch add members via `batchAddMembers`
- Adding a duplicate in a batch reverts
- All 1,000 members are correctly stored after batch add

## Setting Merkle Root

- Owner can set the Merkle root
- Non-owner cannot set the Merkle root

## Verification (Mapping)

- Returns `true` for a registered member
- Returns `false` for a non-member

## Verification (Merkle Proof)

- Valid proof for a registered member returns `true`
- Invalid proof returns `false`
- Proof for a non-member returns `false`

## Gas Profiling

- Gas measurements are recorded for all 5 actions listed above
- Results are presented in a comparison table

---

# Deliverables

Submit the following in your GitHub repository:

- [ ] `MembershipBoard` contract with all 5 functions
- [ ] Off-chain Merkle tree generation script
- [ ] Complete test suite with gas profiling
- [ ] A `README.md` with:
  - How to compile and run tests
  - Gas profiling results in a table format:

| Action | Gas Used |
|--------|----------|
| `addMember` (single call) | |
| `addMember` x1000 (total estimated) | |
| `batchAddMembers` (all 1,000) | |
| `setMerkleRoot` | |
| `verifyMemberByMapping` | |
| `verifyMemberByProof` | |

  - Written answers to all questions above
  - Description of batch sizes tested and findings
