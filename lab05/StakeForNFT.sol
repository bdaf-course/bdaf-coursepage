// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title StakeForNFT
/// @notice Stake your ERC20 tokens, then mint an NFT once you've unstaked.
contract StakeForNFT is ERC721 {
    uint256 private _nextTokenId;

    /// @notice The ERC20 token address that each user staked
    mapping(address => address) public stakedToken;
    /// @notice The amount each user staked
    mapping(address => uint256) public stakedAmount;
    /// @notice Whether the user has already minted their NFT
    mapping(address => bool) public hasMinted;

    constructor() ERC721("Lab5NFT", "L5NFT") {}

    /// @notice Stake an ERC20 token into this contract.
    /// @param token The ERC20 token address to stake
    /// @param amount The amount to stake
    function stake(address token, uint256 amount) external {
        require(!hasMinted[msg.sender], "Already minted");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        stakedToken[msg.sender] = token;
        stakedAmount[msg.sender] = amount;
    }

    /// @notice Unstake and retrieve your ERC20 tokens.
    function unstake() external {
        address token = stakedToken[msg.sender];
        uint256 amount = stakedAmount[msg.sender];
        require(token != address(0), "Nothing staked");

        stakedAmount[msg.sender] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @notice Mint an NFT if the staked ERC20 balance in this contract is 0.
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
}
