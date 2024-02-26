// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "@erc721a/contracts/extensions/ERC721ABurnable.sol";

/// @title FlameStarters NFTs
/// @author Nadina Oates
/// @notice Contract implementing ERC721 standard using the ERC20 token for minting
contract FlameStarters is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {
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

    mapping(uint256 tokenId => string) private s_tokenURIs;
    uint256[] private s_ids = new uint256[](MAX_SUPPLY);

    /**
     * Events
     */
    event SetTokenFee(address indexed sender, uint256 fee);
    event SetEthFee(address indexed sender, uint256 fee);
    event SetMaxPerWallet(address indexed sender, uint256 maxPerWallet);
    event SetBatchLimit(address indexed sender, uint256 batchLimit);
    event MetadataUpdate(uint256 indexed tokenId);

    /// @notice Constructor
    /// @param initialOwner ownerhip is transfered to this address after creation
    /// @param initialFeeAddress address to receive minting fees
    /// @param baseURI base uri for NFT metadata
    /// @dev inherits from ERC721A
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
    function mint(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert FlameStarters_InsufficientMintQuantity();
        if (balanceOf(msg.sender) + quantity > s_maxPerWallet) {
            revert FlameStarters_ExceedsMaxPerWallet();
        }
        if (quantity > s_batchLimit) revert FlameStarters_ExceedsBatchLimit();
        if (_totalSupply() + quantity > MAX_SUPPLY) revert FlameStarters_ExceedsMaxSupply();

        if (i_paymentToken.balanceOf(msg.sender) < s_tokenFee * quantity) {
            revert FlameStarters_InsufficientTokenBalance();
        }
        if (msg.value < s_ethFee * quantity) revert FlameStarters_InsufficientEthFee(msg.value, s_ethFee);

        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < quantity; i++) {
            unchecked {
                _setTokenURI(tokenId, Strings.toString(_randomTokenURI()));
                tokenId++;
            }
        }
        _mint(msg.sender, quantity);

        (bool success,) = payable(s_feeAddress).call{value: msg.value}("");
        if (!success) revert FlameStarters_EthTransferFailed();

        success = i_paymentToken.transferFrom(msg.sender, s_feeAddress, s_tokenFee * quantity);
        if (!success) revert FlameStarters_TokenTransferFailed();
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

    /// @notice Sets the receiver address for the token fee (only owner)
    /// @param feeAddress New receiver address for tokens received through minting
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

    /// @notice retrieves tokenURI
    /// @dev adapted from openzeppelin ERC721URIStorage contract
    /// @param tokenId tokenID of NFT
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = s_tokenURIs[tokenId];
        string memory base = _baseURI();

        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /// @notice checks for supported interface
    /// @dev function override required by ERC721
    /// @param interfaceId interfaceId to be checked
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Internal/Private Functions
     */

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721
    /// @param tokenId token id of NFT
    function _requireOwned(uint256 tokenId) internal view {
        ownerOf(tokenId);
    }

    /// @notice returns total supply
    function _totalSupply() private view returns (uint256) {
        return _nextTokenId();
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

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721URIStorage
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        s_tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    /// @notice generates a random tokenUR
    function _randomTokenURI() private returns (uint256 randomTokenURI) {
        uint256 numAvailableURIs = s_ids.length;
        uint256 randIdx;

        unchecked {
            randIdx =
                uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, block.timestamp))) % numAvailableURIs;
        }

        // get new and nonexisting random id
        randomTokenURI = (s_ids[randIdx] != 0) ? s_ids[randIdx] : randIdx;

        // update helper array
        s_ids[randIdx] = (s_ids[numAvailableURIs - 1] == 0) ? numAvailableURIs - 1 : s_ids[numAvailableURIs - 1];
        s_ids.pop();
    }
}
