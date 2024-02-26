// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";

import {TestInitialized} from "./TestInitialized.t.sol";

contract FuzzHelper {
    mapping(string => bool) public tokenUris;

    function setTokenUri(string memory tokenUri) public {
        tokenUris[tokenUri] = true;
    }

    function isTokenUriSet(string memory tokenUri) public view returns (bool) {
        return tokenUris[tokenUri];
    }
}

contract TestUserFunctions is TestInitialized {
    address USER1 = makeAddr("user-1");
    address USER2 = makeAddr("user-2");
    address NEW_FEE_ADDRESS = makeAddr("tokenFee");

    uint256 constant STARTING_BALANCE = 500_000_000 ether;
    uint256 constant NEW_FEE = 20_000 ether;
    uint256 constant FUZZ_FEE = 100 ether;
    uint256 constant FUZZ_ETH_FEE = 1e9;

    event MetadataUpdate(uint256 indexed tokenId);

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier funded(address account) {
        // fund user ETH
        deal(account, 100 ether);

        // fund user tokens
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }

    modifier mintOpen() {
        // fund user
        vm.startPrank(token.owner());
        nfts.setBatchLimit(MAX_PER_WALLET);
        vm.stopPrank();
        _;
    }

    modifier maxMintAllowed() {
        vm.startPrank(token.owner());
        nfts.setMaxPerWallet(MAX_SUPPLY);
        nfts.setBatchLimit(100);
        nfts.setTokenFee(FUZZ_FEE);
        nfts.setEthFee(FUZZ_ETH_FEE);
        vm.stopPrank();
        _;
    }

    //////////////////////
    // Sucessful mint() //
    /////////////////////

    function test__MintSingleNFT() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
        assertEq(nfts.balanceOf(USER1), 1);
    }

    function test__MintMultipleNFTs() public funded(USER1) mintOpen {
        uint256 ethFee = 3 * nfts.getEthFee();

        uint256 tokenFee = 3 * nfts.getTokenFee();
        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.prank(USER1);
        nfts.mint{value: ethFee}(3);
        assertEq(nfts.balanceOf(USER1), 3);
    }

    function test__MintAllNFTs() public funded(USER1) maxMintAllowed {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();

        for (uint256 index = 0; index < MAX_SUPPLY; index++) {
            vm.roll(index);
            vm.startPrank(USER1);
            token.approve(address(nfts), tokenFee);
            nfts.mint{value: ethFee}(1);
            vm.stopPrank();
        }

        assertEq(nfts.balanceOf(USER1), nfts.totalSupply());

        for (uint256 index = 0; index < nfts.totalSupply(); index++) {
            console.log(nfts.tokenURI(index));
            assertNotEq(bytes(nfts.tokenURI(index)).length, 0);
        }
    }

    function test__RetrieveTokenUri() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();
        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
        assertEq(nfts.balanceOf(USER1), 1);

        console.log(nfts.tokenURI(0));
    }

    function test__ChargesCorrectAmount() public funded(USER1) mintOpen {
        uint256 ethFee = 3 * nfts.getEthFee();
        uint256 tokenFee = 3 * nfts.getTokenFee();

        uint256 initialUserTokenBalance = token.balanceOf(USER1);
        uint256 expectedUserTokenBalance = initialUserTokenBalance - tokenFee;

        uint256 initialUserEthBalance = USER1.balance;
        uint256 expectedUserEthBalance = initialUserEthBalance - ethFee;

        uint256 initialFeeTokenBalance = token.balanceOf(nfts.getFeeAddress());
        uint256 expectedFeeTokenBalance = initialFeeTokenBalance + tokenFee;

        uint256 initialFeeEthBalance = nfts.getFeeAddress().balance;
        uint256 expectedFeeEthBalance = initialFeeEthBalance + ethFee;

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.prank(USER1);
        nfts.mint{value: ethFee}(3);

        assertEq(token.balanceOf(USER1), expectedUserTokenBalance);
        assertEq(USER1.balance, expectedUserEthBalance);
        assertEq(token.balanceOf(nfts.getFeeAddress()), expectedFeeTokenBalance);
        assertEq(nfts.getFeeAddress().balance, expectedFeeEthBalance);
    }

    //////////////////////
    // events          //
    /////////////////////

    function test__EmitEvent__Mint() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.expectEmit(true, true, true, true);
        emit MetadataUpdate(0);

        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
    }

    //////////////////////
    // Revert mint() //
    /////////////////////

    function test__RevertWhen__MintZero() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.expectRevert(FlameStarters.FlameStarters_InsufficientMintQuantity.selector);
        vm.prank(USER1);
        nfts.mint{value: ethFee}(0);
    }

    function test__RevertWhen_MintExceedsBatchLimit() public funded(USER1) mintOpen {
        vm.startPrank(nfts.owner());
        nfts.setMaxPerWallet(12);
        vm.stopPrank();

        uint256 ethFee = 11 * nfts.getEthFee();
        uint256 tokenFee = 11 * nfts.getTokenFee();
        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.expectRevert(FlameStarters.FlameStarters_ExceedsBatchLimit.selector);
        vm.prank(USER1);
        nfts.mint{value: ethFee}(11);
    }

    function test__RevertWhen__MintExceedsMaxWalletLimit() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = (MAX_PER_WALLET + 1) * nfts.getTokenFee();
        vm.startPrank(USER1);
        token.approve(address(nfts), tokenFee);
        nfts.mint{value: MAX_PER_WALLET * ethFee}(MAX_PER_WALLET);
        vm.stopPrank();

        vm.expectRevert(FlameStarters.FlameStarters_ExceedsMaxPerWallet.selector);
        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
    }

    function test__RevertWhen__MaxSupplyExceeded() public funded(USER1) funded(USER2) mintOpen {
        address owner = nfts.owner();
        vm.startPrank(owner);
        nfts.setMaxPerWallet(MAX_SUPPLY);
        nfts.setBatchLimit(100);
        nfts.setTokenFee(10 ether);

        vm.startPrank(USER1);
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();
        for (uint256 index = 0; index < MAX_SUPPLY; index++) {
            token.approve(address(nfts), tokenFee);
            nfts.mint{value: ethFee}(1);
        }
        vm.stopPrank();

        vm.prank(USER2);
        token.approve(address(nfts), tokenFee);

        vm.expectRevert(FlameStarters.FlameStarters_ExceedsMaxSupply.selector);
        vm.prank(USER2);
        nfts.mint{value: ethFee}(1);
    }

    function test__RevertWhen__InsufficientTokenBalance() public funded(USER1) mintOpen {
        uint256 insufficientTokenBalance = 5000 ether;
        uint256 ethFee = nfts.getEthFee();

        vm.startPrank(USER1);
        token.transfer(USER2, STARTING_BALANCE - insufficientTokenBalance);
        vm.stopPrank();

        vm.prank(USER1);
        token.approve(address(nfts), insufficientTokenBalance);

        vm.expectRevert(FlameStarters.FlameStarters_InsufficientTokenBalance.selector);
        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
    }

    function test__RevertWhen__InsufficientEthFee() public funded(USER1) mintOpen {
        uint256 tokenFee = nfts.getTokenFee();
        uint256 insufficientFee = nfts.getEthFee() / 2;

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        vm.expectRevert(
            abi.encodeWithSelector(
                FlameStarters.FlameStarters_InsufficientEthFee.selector, insufficientFee, nfts.getEthFee()
            )
        );
        vm.prank(USER1);
        nfts.mint{value: insufficientFee}(1);
    }

    function test__RevertsWhen__TokenTransferFails() public funded(USER1) mintOpen {
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();
        vm.prank(USER1);
        token.approve(address(nfts), tokenFee);

        address feeAccount = nfts.getFeeAddress();
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(token.transferFrom.selector, USER1, feeAccount, tokenFee),
            abi.encode(false)
        );

        vm.expectRevert(FlameStarters.FlameStarters_TokenTransferFailed.selector);
        vm.prank(USER1);
        nfts.mint{value: ethFee}(1);
    }

    // function test__RevertsWhen__EthTransferFails() public funded(USER1) mintOpen {
    //     uint256 ethFee = nfts.getEthFee();
    //     uint256 tokenFee = nfts.getTokenFee();
    //     vm.prank(USER1);
    //     token.approve(address(nfts), tokenFee);

    //     address feeAccount = nfts.getFeeAddress();
    //     vm.mockCall(feeAccount, ethFee, "", abi.encode(false));

    //     vm.expectRevert(FlameStarters.FlameStarters_EthTransferFailed.selector);
    //     vm.prank(USER1);
    //     nfts.mint{value: ethFee}(1);
    // }

    ////////////////////////
    // Stateless Fuzzing //
    ///////////////////////

    function test__Fuzz__MintNfts(address account, uint256 numOfNfts) public funded(account) maxMintAllowed skipFork {
        numOfNfts = bound(numOfNfts, 1, 100);
        vm.assume(account != address(0));

        uint256 ethFee = numOfNfts * nfts.getEthFee();

        vm.startPrank(account);
        token.approve(address(nfts), numOfNfts * FUZZ_FEE);
        nfts.mint{value: ethFee}(numOfNfts);
        vm.stopPrank();

        assertEq(nfts.balanceOf(account), numOfNfts);
    }

    function test__Fuzz__TransferNfts(address account, address receiver, uint256 numOfNfts)
        public
        funded(account)
        maxMintAllowed
        skipFork
    {
        numOfNfts = bound(numOfNfts, 1, 100);
        vm.assume(account != address(0));
        vm.assume(receiver != address(0));

        uint256 ethFee = numOfNfts * nfts.getEthFee();

        vm.startPrank(account);
        token.approve(address(nfts), numOfNfts * FUZZ_FEE);
        nfts.mint{value: ethFee}(numOfNfts);
        vm.stopPrank();

        assertEq(nfts.balanceOf(account), numOfNfts);
        for (uint256 index = 0; index < nfts.totalSupply(); index++) {
            assertEq(nfts.ownerOf(index), account);
            vm.prank(account);
            nfts.transferFrom(account, receiver, index);
            assertEq(nfts.ownerOf(index), receiver);
        }

        assertEq(nfts.balanceOf(receiver), numOfNfts);
    }

    /// forge-config: default.fuzz.runs = 3
    function test__Fuzz__UniqueTokenUris(uint256 roll) public funded(USER1) maxMintAllowed skipFork {
        roll = bound(roll, 1, 1000);
        FuzzHelper fuzzHelper = new FuzzHelper();
        uint256 ethFee = nfts.getEthFee();
        uint256 tokenFee = nfts.getTokenFee();

        vm.prank(USER1);
        token.approve(address(nfts), tokenFee * MAX_SUPPLY);
        vm.roll(roll);
        for (uint256 index = 0; index < MAX_SUPPLY; index++) {
            vm.prank(USER1);
            nfts.mint{value: ethFee}(1);
            string memory tokenUri = nfts.tokenURI(index);
            console.log(tokenUri);
            assertEq(nfts.ownerOf(index), USER1);
            assertEq(fuzzHelper.isTokenUriSet(tokenUri), false);
            fuzzHelper.setTokenUri(tokenUri);
            vm.roll(roll + index);
        }

        assertEq(nfts.balanceOf(USER1), nfts.totalSupply());
    }
}
