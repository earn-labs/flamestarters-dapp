// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";

import {TestInitialized} from "../unit/TestInitialized.t.sol";

import {Handler} from "./handlers/Handler.sol";

contract TestInvariants is TestInitialized {
    Handler handler;

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    function setUp() external override {
        deployment = new DeployFlameStarters();
        (nfts, helperConfig) = deployment.run();

        (initialOwner, feeAddress, tokenAddress) = helperConfig.activeNetworkConfig();
        token = ERC20Token(nfts.getPaymentToken());

        handler = new Handler(nfts, token);

        excludeSender(address(0));
        excludeSender(address(token));
        excludeSender(address(nfts));
        excludeSender(address(handler));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Handler.mintNfts.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    function invariant__TotalSupplyIsLessThanOrEqualMaxSupply() public skipFork {
        assertLt(nfts.totalSupply(), MAX_SUPPLY);
    }

    function invariant__TotalCollectedFees() public skipFork {
        assertEq(token.balanceOf(nfts.getFeeAddress()), nfts.totalSupply() * handler.getFuzzFee());
        assertEq(nfts.getFeeAddress().balance, nfts.totalSupply() * handler.getFuzzEthFee());
    }
}
