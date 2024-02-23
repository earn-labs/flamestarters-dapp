// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FlameStarters} from "../../src/FlameStarters.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeployFlameStarters is Script {
    string public baseUri = "ipfs://bafybeia46ygme5csjbmqa73eacqcxmkfmmsajzkgvcxcr7a6tv2bl26nla/";
    HelperConfig public helperConfig;

    function run() external returns (FlameStarters, HelperConfig) {
        helperConfig = new HelperConfig();
        (address initialOwner, address feeAddress, address tokenAddress) = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", initialOwner);
        console.log("fee address: ", feeAddress);
        console.log("token address: ", tokenAddress);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        FlameStarters nfts = new FlameStarters(initialOwner, feeAddress, tokenAddress, baseUri);
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
