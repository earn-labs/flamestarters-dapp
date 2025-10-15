// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FlameStarters} from "../../src/FlameStarters.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {DeployFlameStarters} from "../../script/deployment/DeployFlameStarters.s.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestInitialized is Test {
    // configuration
    DeployFlameStarters deployment;
    HelperConfig helperConfig;

    FlameStarters nfts;
    ERC20Token token;

    // constructor arguments
    address initialOwner;
    address feeAddress;
    address tokenAddress;

    // helper variables
    uint256 constant TOKEN_FEE = 1_000_000 ether;
    uint256 constant ETH_FEE = 0.1 ether;
    uint256 constant MAX_SUPPLY = 177;
    uint256 constant BATCH_LIMIT = 0;
    uint256 constant MAX_PER_WALLET = 5;

    function setUp() external virtual {
        deployment = new DeployFlameStarters();
        (nfts, helperConfig) = deployment.run();

        (initialOwner, feeAddress, tokenAddress) = helperConfig.activeNetworkConfig();
        token = ERC20Token(nfts.getPaymentToken());
    }
}
