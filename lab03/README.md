# BDaF 2026 Lab03 — Signature-Based Token Approval

**Deadline:** March 17th 

**Submission:** https://forms.gle/Xgkt85pWFio8k6dN8

---

# Readings

### Ethereum Basics
- https://ethereum.org/en/developers/docs/accounts/

### OpenZeppelin
- https://docs.openzeppelin.com/contracts/5.x/api/utils#ECDSA

### Solidity Cryptography
- https://docs.soliditylang.org/en/latest/units-and-global-variables.html#mathematical-and-cryptographic-functions

---

# Project Overview

In Ethereum, many interactions require users to send transactions and pay gas. However, users can also **sign messages off-chain** and allow someone else to submit those signatures on-chain.

In this lab, you will implement a token approval mechanism where the **token holder signs an approval message off-chain**, and **another user submits the signed message on-chain** to update the allowance.

The goal of this assignment is to help you understand:

- how signatures work in Ethereum
- how to verify signatures in Solidity
- how replay attacks occur
- how to prevent replay attacks using nonces

You will use **OpenZeppelin’s `ECDSA` library** to recover the signer from a signature.

---

# Contract Requirement

Create **ONE ERC20 token contract** with:

- total supply of **100,000,000 tokens**
- **18 decimals**
- any **token name and symbol** of your choice

Your contract must implement the following.

---

## Standard ERC20 functionality

Using **OpenZeppelin ERC20** is allowed.

Your token must support:

- `transfer`
- `approve`
- `transferFrom`
- `allowance`

---

## Signature-Based Approval

Implement the following function:

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
) public
```

This function allows `spender` to receive an allowance from `owner` if a **valid signature from `owner`** is provided.

---

### Signed Message Contents

The signed message must include the following fields:

```
owner
spender
value
nonce
deadline
address(this)
```

Students should compute a hash similar to:

```solidity
bytes32 hash = keccak256(
    abi.encodePacked(
        owner,
        spender,
        value,
        nonce,
        deadline,
        address(this)
    )
);
```

Then verify the signature using OpenZeppelin:

```solidity
address signer = ECDSA.recover(message, signature);
```

---

## Nonce Tracking

Implement:

```solidity
mapping(address => uint256) public nonces;
```

Requirements:

- each successful `permit()` must increment the owner's nonce
- signatures using an old nonce must fail

---

## Deadline

The signature must contain a **deadline timestamp**.

Requirements:

- if `block.timestamp > deadline`, the transaction must revert

---

## Successful Permit

If the signature is valid and all checks pass, update the allowance:

```solidity
_approve(owner, spender, value);
```

---

# Project Requirement

The project must satisfy the following:

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

The contract must be deployed on **a public testnet**.

Record the following:

- deployed contract address
- contract verification link
- transaction hashes demonstrating the required flow

---

# Required Flow Demonstration

Demonstrate the following sequence:

1. Alice receives tokens
2. Alice signs an approval message for Bob **off-chain**
3. Bob submits `permit()` using Alice's signature
4. Bob calls `transferFrom()` to transfer tokens from Alice

Record the transaction hashes.

---

# Minimum Test Cases

Your tests must include the following.

---

## Signature Verification

- valid signature successfully executes `permit`
- signature from wrong signer fails

---

## Nonce Protection

- nonce increases after successful permit
- reusing the same signature fails

---

## Expiry

- expired signature fails

---

## Allowance

- allowance is correctly updated after permit
- `transferFrom()` works after permit
- `transferFrom()` fails if permit was not executed

---

# Hints

Use OpenZeppelin's `ECDSA` library.

Example:

```solidity
bytes32 hash = keccak256(...);
bytes32 message = ECDSA.toEthSignedMessageHash(hash);
address signer = ECDSA.recover(message, signature);
```

Then verify:

```solidity
require(signer == owner);
```

Be careful with:

- nonce usage
- replay attacks
- signature encoding
- message hashing

---

# Deliverables

Submit the following:

- your GitHub repository
- test files
- deployed contract address
- contract verification link
- transaction hashes demonstrating the required flow

Also include a short write-up answering:

1. Why are signatures useful in Ethereum applications?
2. What is a replay attack?
3. How does your contract prevent replay attacks?
