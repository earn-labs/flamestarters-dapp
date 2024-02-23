// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721, ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";
import {TestInitialized} from "./TestInitialized.t.sol";

contract TestDeployment is TestInitialized {
    // configuration

    function test__Initialization() public {
        ERC20 paymentToken = ERC20(nfts.getPaymentToken());
        string memory feeTokenSymbol = paymentToken.symbol();
        assertEq(feeTokenSymbol, "0X177");
        assertEq(nfts.name(), "FlameStarters");
        assertEq(nfts.symbol(), "FLAMESTARTER");
        assertEq(nfts.getTokenFee(), TOKEN_FEE);
        assertEq(nfts.getEthFee(), ETH_FEE);
        assertEq(nfts.getMaxSupply(), MAX_SUPPLY);
        assertEq(nfts.getBatchLimit(), BATCH_LIMIT);
        assertEq(nfts.getMaxPerWallet(), MAX_PER_WALLET);
    }

    function test__ConstructorArguments() public {
        assertEq(nfts.owner(), initialOwner);
        assertEq(nfts.getFeeAddress(), feeAddress);
        assertEq(nfts.getPaymentToken(), tokenAddress);
        assertEq(nfts.getBaseUri(), deployment.baseUri());
    }

    function test__GetterFunctions() public {
        assertEq(nfts.getMaxSupply(), 10000);
        assertEq(nfts.supportsInterface(0x80ac58cd), true);

        vm.expectRevert(IERC721A.OwnerQueryForNonexistentToken.selector);
        nfts.tokenURI(0);
    }

    function test__NoBaseUriOnDeployment() public {
        vm.expectRevert(FlameStarters.FlameStarters_NoBaseURI.selector);
        new FlameStarters(initialOwner, feeAddress, tokenAddress, "");
    }
}
