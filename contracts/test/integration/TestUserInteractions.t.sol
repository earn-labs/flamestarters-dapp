// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";
import {MintNfts, TransferNft, ApproveNft} from "../../script/interactions/UserInteractions.s.sol";

contract UserInteractionsTest is Test {
    FlameStarters nftContract;
    HelperConfig helperConfig;
    IERC20 token;

    // constructor arguments
    address initialOwner;
    address feeAddress;
    address tokenAddress;

    // helper variables
    address USER = makeAddr("user");
    address OWNER;
    uint256 constant STARTING_BALANCE = 10_000_000 ether;
    uint256 constant MAX_PER_WALLET = 5;

    modifier fundedAndApproved() {
        // fund user with eth
        deal(USER, 10 ether);

        // fund user with tokens
        vm.prank(OWNER);
        token.transfer(msg.sender, STARTING_BALANCE);
        vm.prank(msg.sender);
        token.approve(address(nftContract), STARTING_BALANCE);
        _;
    }

    modifier mintOpen() {
        vm.startPrank(OWNER);
        nftContract.setBatchLimit(MAX_PER_WALLET - 1);
        vm.stopPrank();
        _;
    }

    function setUp() external {
        DeployFlameStarters deployment = new DeployFlameStarters();
        (nftContract, helperConfig) = deployment.run();

        (initialOwner, feeAddress, tokenAddress) = helperConfig.activeNetworkConfig();
        token = ERC20Token(nftContract.getPaymentToken());
        OWNER = nftContract.owner();
    }

    function test__integration__UserCanMintSingleNft() public fundedAndApproved mintOpen {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintSingleNft(address(nftContract));

        assert(nftContract.balanceOf(msg.sender) == 1);
    }

    function test__integration__UserCanMintMultipleNfts() public fundedAndApproved mintOpen {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintMultipleNfts(address(nftContract));

        assert(nftContract.balanceOf(msg.sender) == 3);
    }

    function test__integration__UserCanTransferNft() public fundedAndApproved mintOpen {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintSingleNft(address(nftContract));
        assert(nftContract.balanceOf(msg.sender) == 1);

        TransferNft transferNft = new TransferNft();
        transferNft.transferNft(address(nftContract));
        assert(nftContract.balanceOf(msg.sender) == 0);
    }

    function test__integration__UserCanApproveNft() public fundedAndApproved mintOpen {
        uint256 fee = nftContract.getEthFee();
        vm.prank(msg.sender);
        nftContract.mint{value: fee}(1);
        ApproveNft approveNft = new ApproveNft();
        approveNft.approveNft(address(nftContract));

        assert(nftContract.getApproved(1) == makeAddr("sender"));
    }
}
