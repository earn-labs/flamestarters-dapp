// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";

import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";

import {TestInitialized} from "./TestInitialized.t.sol";

contract TestOwnerFunctions is TestInitialized {
    address USER = makeAddr("user");
    address NEW_FEE_ADDRESS = makeAddr("fee");

    uint256 constant STARTING_BALANCE = 500_000 * 10 ** 18;
    uint256 constant NEW_FEE = 20_000 * 10 ** 18;

    event SetTokenFee(address indexed sender, uint256 fee);
    event SetEthFee(address indexed sender, uint256 fee);
    event SetMaxPerWallet(address indexed sender, uint256 maxPerWallet);
    event SetBatchLimit(address indexed sender, uint256 batchLimit);

    modifier funded() {
        // fund user with eth
        deal(USER, 10 ether);
        // fund user with token
        vm.startPrank(nfts.owner());
        token.transfer(USER, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }

    modifier mintOpen() {
        // fund user
        vm.startPrank(nfts.owner());
        nfts.setBatchLimit(MAX_PER_WALLET - 1);
        vm.stopPrank();
        _;
    }

    function test__OwnerCanSetTokenFee() public {
        address owner = nfts.owner();
        vm.prank(owner);
        nfts.setTokenFee(NEW_FEE);
        assertEq(nfts.getTokenFee(), NEW_FEE);
    }

    function test__OwnerCanSetEthFee() public {
        address owner = nfts.owner();
        vm.prank(owner);
        nfts.setEthFee(NEW_FEE);
        assertEq(nfts.getEthFee(), NEW_FEE);
    }

    function test__OwnerCanSetFeeAddress() public {
        address owner = nfts.owner();
        vm.prank(owner);
        nfts.setFeeAddress(NEW_FEE_ADDRESS);
        assertEq(nfts.getFeeAddress(), NEW_FEE_ADDRESS);
    }

    function test__OwnerCanSetBatchLimit() public mintOpen {
        address owner = nfts.owner();
        vm.prank(owner);
        nfts.setBatchLimit(3);
        assertEq(nfts.getBatchLimit(), 3);
    }

    function test__OwnerCanSetMaxPerWallet() public mintOpen {
        address owner = nfts.owner();
        vm.prank(owner);
        nfts.setMaxPerWallet(11);
        assertEq(nfts.getMaxPerWallet(), 11);
    }

    function test__OwnerCanWithdrawTokens() public funded {
        vm.prank(USER);
        token.transfer(address(nfts), STARTING_BALANCE / 2);
        uint256 contractBalance = token.balanceOf(address(nfts));
        assertGt(contractBalance, 0);
        uint256 initialBalance = token.balanceOf(nfts.owner());

        vm.startPrank(nfts.owner());
        nfts.withdrawTokens(address(token), nfts.owner());
        vm.stopPrank();
        uint256 newBalance = token.balanceOf(nfts.owner());
        assertEq(token.balanceOf(address(nfts)), 0);
        assertGt(newBalance, initialBalance);
    }

    //////////////////////
    // events          //
    /////////////////////

    function test__EmitEvent__SetTokenFee() public {
        address owner = nfts.owner();

        vm.expectEmit(true, true, true, true);
        emit SetTokenFee(owner, NEW_FEE);

        vm.prank(owner);
        nfts.setTokenFee(NEW_FEE);
    }

    function test__EmitEvent__SetEthFee() public {
        address owner = nfts.owner();

        vm.expectEmit(true, true, true, true);
        emit SetEthFee(owner, NEW_FEE);

        vm.prank(owner);
        nfts.setEthFee(NEW_FEE);
    }

    function test__EmitEvent__SetMaxPerWallet() public {
        address owner = nfts.owner();

        vm.expectEmit(true, true, true, true);
        emit SetMaxPerWallet(owner, MAX_SUPPLY);

        vm.prank(owner);
        nfts.setMaxPerWallet(MAX_SUPPLY);
    }

    function test__EmitEvent__SetBatchLimit() public {
        address owner = nfts.owner();

        vm.expectEmit(true, true, true, true);
        emit SetBatchLimit(owner, 3);

        vm.prank(owner);
        nfts.setBatchLimit(3);
    }

    //////////////////////
    // Revert mint() //
    /////////////////////

    function test__RevertWhen__FeeAddressIsZero() public {
        address owner = nfts.owner();
        vm.prank(owner);

        vm.expectRevert(FlameStarters.FlameStarters_FeeAddressIsZeroAddress.selector);
        nfts.setFeeAddress(address(0));
    }

    function test__RevertWhen__BatchLimitGreaterThanMaxPerWallet() public mintOpen {
        address owner = nfts.owner();
        vm.prank(owner);

        vm.expectRevert(FlameStarters.FlameStarters_BatchLimitExceedsMaxPerWallet.selector);
        nfts.setBatchLimit(11);
    }

    function test__RevertWhen__BatchLimitTooHigh() public {
        address owner = nfts.owner();
        vm.prank(owner);

        vm.expectRevert(FlameStarters.FlameStarters_BatchLimitTooHigh.selector);
        nfts.setBatchLimit(101);
    }

    function test__RevertWhen__MaxPerWalletGreaterThanSupply() public {
        address owner = nfts.owner();
        vm.prank(owner);

        vm.expectRevert(FlameStarters.FlameStarters_MaxPerWalletExceedsMaxSupply.selector);
        nfts.setMaxPerWallet(10001);
    }

    function test__RevertWhen__MaxPerWalletSmallerThanBatchLimit() public mintOpen {
        address owner = nfts.owner();
        vm.prank(owner);

        vm.expectRevert(FlameStarters.FlameStarters_MaxPerWalletSmallerThanBatchLimit.selector);
        nfts.setMaxPerWallet(3);
    }

    function test__RevertWhen__NotOwnerSetsTokenFee() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nfts.setTokenFee(NEW_FEE);
    }

    function test__RevertWhen__NotOwnerSetsEthFee() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nfts.setEthFee(NEW_FEE);
    }

    function test__RevertWhen__NotOwnerSetsFeeAddress() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nfts.setFeeAddress(NEW_FEE_ADDRESS);
    }

    function test__RevertWhen__NotOwnerSetsBatchLimit() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nfts.setBatchLimit(10);
    }

    function test__RevertWhen__NotOwnerSetsMaxPerWallet() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nfts.setMaxPerWallet(100);
    }

    function test__RevertWhen__NotOwnerWithdrawsTokens() public funded {
        vm.prank(USER);
        token.transfer(address(nfts), STARTING_BALANCE / 2);
        uint256 contractBalance = token.balanceOf(address(nfts));
        assertGt(contractBalance, 0);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        vm.prank(USER);
        nfts.withdrawTokens(address(token), USER);
    }
}
