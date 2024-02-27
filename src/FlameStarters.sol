// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "@erc721a/contracts/extensions/ERC721ABurnable.sol";

/// @title FlameStarters NFTs
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using the ERC20 token and ETH for minting
/// @dev Inherits from ERC721A and ERC721ABurnable and openzeppelin Ownable
contract FlameStarters is ERC721A, ERC721ABurnable, Ownable {
    /**
     * Errors
     */
    error FlameStarters_InsufficientTokenBalance();
    error FlameStarters_InsufficientMintQuantity();
    error FlameStarters_ExceedsMaxSupply();
    error FlameStarters_ExceedsMaxPerWallet();
    error FlameStarters_ExceedsBatchLimit();
    error FlameStarters_FeeAddressIsZeroAddress();
    error FlameStarters_TokenTransferFailed();
    error FlameStarters_InsufficientEthFee(uint256 value, uint256 fee);
    error FlameStarters_EthTransferFailed();
    error FlameStarters_MaxPerWalletExceedsMaxSupply();
    error FlameStarters_MaxPerWalletSmallerThanBatchLimit();
    error FlameStarters_BatchLimitExceedsMaxPerWallet();
    error FlameStarters_BatchLimitTooHigh();
    error FlameStarters_NonexistentToken(uint256);
    error FlameStarters_TokenUriError();
    error FlameStarters_NoBaseURI();

    /**
     * Storage Variables
     */
    uint256 private constant MAX_SUPPLY = 177;
    IERC20 private immutable i_paymentToken;

    string private s_baseTokenURI;
    address private s_feeAddress;
    uint256 private s_tokenFee = 1_000_000 ether;
    uint256 private s_ethFee = 0.1 ether;
    uint256 private s_maxPerWallet = 5;
    uint256 private s_batchLimit = 0;

    /**
     * Events
     */
    event SetTokenFee(address indexed sender, uint256 fee);
    event SetEthFee(address indexed sender, uint256 fee);
    event SetMaxPerWallet(address indexed sender, uint256 maxPerWallet);
    event SetBatchLimit(address indexed sender, uint256 batchLimit);

    /// @notice Constructor
    /// @param initialOwner ownerhip is transfered to this address after creation
    /// @param initialFeeAddress address to receive minting fees
    /// @param baseURI base uri for NFT metadata
    constructor(address initialOwner, address initialFeeAddress, address tokenAddress, string memory baseURI)
        ERC721A("FlameStarters", "FLAMESTARTER")
        Ownable(msg.sender)
    {
        if (initialFeeAddress == address(0)) revert FlameStarters_FeeAddressIsZeroAddress();
        if (bytes(baseURI).length == 0) revert FlameStarters_NoBaseURI();

        s_feeAddress = initialFeeAddress;
        i_paymentToken = IERC20(tokenAddress);
        _setBaseURI(baseURI);
        _transferOwnership(initialOwner);
    }

    receive() external payable {}

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable {
        if (quantity == 0) revert FlameStarters_InsufficientMintQuantity();
        if (balanceOf(msg.sender) + quantity > s_maxPerWallet) {
            revert FlameStarters_ExceedsMaxPerWallet();
        }
        if (quantity > s_batchLimit) revert FlameStarters_ExceedsBatchLimit();
        if (totalSupply() + quantity > MAX_SUPPLY) revert FlameStarters_ExceedsMaxSupply();

        if (i_paymentToken.balanceOf(msg.sender) < s_tokenFee * quantity) {
            revert FlameStarters_InsufficientTokenBalance();
        }
        if (msg.value < s_ethFee * quantity) revert FlameStarters_InsufficientEthFee(msg.value, s_ethFee);

        _mint(msg.sender, quantity);

        bool success = i_paymentToken.transferFrom(msg.sender, s_feeAddress, s_tokenFee * quantity);
        if (!success) revert FlameStarters_TokenTransferFailed();

        (success,) = payable(s_feeAddress).call{value: msg.value}("");
        if (!success) revert FlameStarters_EthTransferFailed();
    }

    /// @notice Sets minting fee in terms of ERC20 tokens (only owner)
    /// @param fee New fee in ERC20 tokens
    function setTokenFee(uint256 fee) external onlyOwner {
        s_tokenFee = fee;
        emit SetTokenFee(msg.sender, fee);
    }

    /// @notice Sets minting fee in ETH (only owner)
    /// @param fee New fee in ETH
    function setEthFee(uint256 fee) external onlyOwner {
        s_ethFee = fee;
        emit SetEthFee(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token/ETH fee (only owner)
    /// @param feeAddress New receiver address for tokens and ETH received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        if (feeAddress == address(0)) {
            revert FlameStarters_FeeAddressIsZeroAddress();
        }
        s_feeAddress = feeAddress;
    }

    /// @notice Sets the maximum number of nfts per wallet (only owner)
    /// @param maxPerWallet Maximum number of nfts that can be held by one account
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        if (maxPerWallet > MAX_SUPPLY) {
            revert FlameStarters_MaxPerWalletExceedsMaxSupply();
        }
        if (maxPerWallet < s_batchLimit) {
            revert FlameStarters_MaxPerWalletSmallerThanBatchLimit();
        }
        s_maxPerWallet = maxPerWallet;
        emit SetMaxPerWallet(msg.sender, maxPerWallet);
    }

    /// @notice Sets batch limit - maximum number of nfts that can be minted at once (only owner)
    /// @param batchLimit Maximum number of nfts that can be minted at once
    function setBatchLimit(uint256 batchLimit) external onlyOwner {
        if (batchLimit > 100) revert FlameStarters_BatchLimitTooHigh();
        if (batchLimit > s_maxPerWallet) {
            revert FlameStarters_BatchLimitExceedsMaxPerWallet();
        }
        s_batchLimit = batchLimit;
        emit SetBatchLimit(msg.sender, batchLimit);
    }

    /// @notice Withdraw tokens from contract (only owner)
    /// @param tokenAddress Contract address of token to be withdrawn
    /// @param receiverAddress Tokens are withdrawn to this address
    /// @return success of withdrawal
    function withdrawTokens(address tokenAddress, address receiverAddress) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
        if (!success) revert FlameStarters_TokenTransferFailed();
    }

    /// @notice Withdraw ETH from contract (only owner)
    /// @param receiverAddress ETH withdrawn to this address
    /// @return success of withdrawal
    function withdrawETH(address receiverAddress) external onlyOwner returns (bool success) {
        uint256 amount = address(this).balance;
        (success,) = payable(receiverAddress).call{value: amount}("");
        if (!success) revert FlameStarters_EthTransferFailed();
    }

    /**
     * Getter Functions
     */

    /// @notice Gets payment token address
    function getPaymentToken() external view returns (address) {
        return address(i_paymentToken);
    }

    /// @notice Gets maximum supply
    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /// @notice Gets minting token fee in ERC20
    function getTokenFee() external view returns (uint256) {
        return s_tokenFee;
    }

    /// @notice Gets minting fee in ETH
    function getEthFee() external view returns (uint256) {
        return s_ethFee;
    }

    /// @notice Gets address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }

    /// @notice Gets number of nfts allowed minted at once
    function getBatchLimit() external view returns (uint256) {
        return s_batchLimit;
    }

    /// @notice Gets maximum number of nfts allowed per address
    function getMaxPerWallet() external view returns (uint256) {
        return s_maxPerWallet;
    }

    /// @notice Gets base uri
    function getBaseUri() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * Public Functions
     */

    /// @notice checks for supported interface
    /// @dev function override required by ERC721
    /// @param interfaceId interfaceId to be checked
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Internal/Private Functions
     */
    /// @notice sets first tokenId to 1
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    /// @notice Sets base uri
    /// @param baseURI base uri for NFT metadata
    function _setBaseURI(string memory baseURI) private {
        s_baseTokenURI = baseURI;
    }

    /// @notice Retrieves base uri
    function _baseURI() internal view override returns (string memory) {
        return s_baseTokenURI;
    }
}
