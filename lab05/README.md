# BDaF 2026 Lab05 — Proxy Patterns & Upgradeable Contracts

**Deadline:** April 7th

**Submission:** https://forms.gle/hntPA1M7USo3sQup9

---

# Readings

### Proxy Patterns
- https://docs.openzeppelin.com/contracts/5.x/api/proxy
- https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable

### UUPS Pattern
- https://eips.ethereum.org/EIPS/eip-1822
- https://docs.openzeppelin.com/contracts/5.x/api/proxy#UUPSUpgradeable

### OpenZeppelin Upgradeable Contracts
- https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable

---

# Overview

In this lab, you will learn about **proxy patterns** and **upgradeable contracts** — a fundamental building block in smart contract development.

You will:

1. Deploy your own **upgradeable ERC20** token using OpenZeppelin's upgradeable library and a proxy pattern.
2. Stake your token into a contract deployed on-chain to receive an NFT.
3. Discover that things are not always what they seem on-chain.
4. Use your knowledge of proxy patterns to solve the challenge.

---

# Part 1: Deploy an Upgradeable ERC20

Deploy an ERC20 token using **OpenZeppelin's upgradeable contracts** with the **UUPS proxy pattern**.

### Requirements

- Use `ERC20Upgradeable` from `@openzeppelin/contracts-upgradeable`
- Use `UUPSUpgradeable` for the upgrade mechanism
- Use `OwnableUpgradeable` for access control
- Deploy behind an `ERC1967Proxy` from `@openzeppelin/contracts`
- The token should have:
  - Any name and symbol of your choice
  - 18 decimals
  - An `initialize` function that mints an initial supply to the deployer
- No extra functions beyond standard ERC20 + UUPS upgrade mechanism

Your V1 implementation should look something like:


Deploy the proxy:

```solidity
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Deploy implementation
MyTokenV1 impl = new MyTokenV1();

// Deploy proxy with initialization
bytes memory data = abi.encodeCall(
    MyTokenV1.initialize,
    ("MyToken", "MTK", 1000000 * 1e18)
);
ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);

// Interact via proxy address
MyTokenV1 token = MyTokenV1(address(proxy));
```

---

# Part 2: Stake Your Tokens

A `StakeForNFT` contract has been deployed on Ethereum Sepolia testnet. The contract promises to mint you an NFT after you stake your ERC20 tokens.

**Deployed contract address:** [`0xa73caE55DF45E8902c5A9df832D1705d6232f61E`](https://sepolia.etherscan.io/address/0xa73caE55DF45E8902c5A9df832D1705d6232f61E)

Here is the source code of the contract: [StakeForNFT.sol](./StakeForNFT.sol)

### Steps

1. Approve the `StakeForNFT` contract to spend your ERC20 tokens.
2. Call `stake(address token, uint256 amount, string studentId)` with your ERC20 proxy address, an amount of your choice, and your student ID.

---

# Part 3: Try to Unstake

Now try calling `unstake()` on the deployed `StakeForNFT` contract.

**Questions:**
1. Did calling `unstake()` revert? Did you actually get your tokens back?
2. What does this tell you about trusting unverified contract source code? A function with the same name and signature can exist on-chain but behave completely differently from what you were shown.

---

# Part 4: Get Your Tokens Back & Mint the NFT

The `mint()` function on the deployed contract works as follows:

1. It looks up the ERC20 token address you registered when you called `stake`.
2. It checks whether the **balance of that ERC20 token held by the StakeForNFT contract** is 0.
3. If the balance is 0, it mints an NFT to you.

```solidity
function mint() external {
    address token = stakedToken[msg.sender];
    require(token != address(0), "No token registered");
    require(!hasMinted[msg.sender], "Already minted");
    require(
        IERC20(token).balanceOf(address(this)) == 0,
        "Token balance must be 0"
    );

    hasMinted[msg.sender] = true;
    _mint(msg.sender, _nextTokenId++);
}
```

Your task: **figure out a way to make the StakeForNFT contract's balance of your ERC20 become 0**, then call `mint()` to receive your NFT.

> Hint: Remember what kind of ERC20 you deployed in Part 1.

---

# Project Requirement

- Project MUST use **Hardhat or Foundry**
- The ERC20 token must be deployed on **Ethereum Sepolia testnet** using a UUPS proxy
- You must interact with the deployed `StakeForNFT` contract on the same testnet

---

# Deliverables

Submit the following items in your GitHub repository's lab05 README.md (excluding transaction hashes and addresses. You should submit them in the google form) :

1. Your GitHub repository containing:
   - Your upgradeable ERC20 contract(s)
   - Deployment scripts
2. Deployed ERC20 proxy contract address
3. Transaction hash of your `stake` call
4. Transaction hash of your `unstake` attempt
5. A short write-up answering:
   - What happened when you called `unstake`? Did you get your tokens back?
   - How did you retrieve your tokens?
   - What does this teach you about interacting with unverified contracts?
5. Transaction hash of your successful `mint` call (NFT received)

---

# Reference

- Ethereum Sepolia Testnet Explorer: https://sepolia.etherscan.io/
- Sepolia Faucet: https://cloud.google.com/application/web3/faucet/ethereum/sepolia
- OpenZeppelin Upgradeable Contracts: https://docs.openzeppelin.com/contracts/5.x/upgradeable
- OpenZeppelin UUPS Proxy: https://docs.openzeppelin.com/contracts/5.x/api/proxy#UUPSUpgradeable
