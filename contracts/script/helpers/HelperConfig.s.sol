// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

contract HelperConfig is Script {
    // EARN deployment arguments
    address public constant TOKENOWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // chain configurations
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address initialOwner;
        address feeAddress;
        address tokenAddress;
    }

    constructor() {
        if (block.chainid == 1 || block.chainid == 56 || block.chainid == 8453) {
            activeNetworkConfig = getMainnetConfig();
        } else if (
            block.chainid == 11155111 || block.chainid == 97 || block.chainid == 84532 || block.chainid == 84531
                || block.chainid == 80001
        ) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0xCbA52038BF0814bC586deE7C061D6cb8B203f8e1,
            feeAddress: 0xCbA52038BF0814bC586deE7C061D6cb8B203f8e1,
            tokenAddress: 0x17cE1F8De9235EC9aACd58c56de5F8eA4bD8E063
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0x4671a210C4CF44C43dC5E44DAf68e64D46cdc703,
            feeAddress: 0x0d8470Ce3F816f29AA5C0250b64BfB6421332829,
            tokenAddress: 0xB0BcB4eDE80978f12aA467F7344b9bdBCd2497f3
        });
    }

    function getLocalForkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            feeAddress: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            tokenAddress: 0xEf3B8512196Ab65F8603b82D1FA5a29bb5ADFeD0
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contract
        vm.startBroadcast();
        ERC20Token token = new ERC20Token(TOKENOWNER);
        vm.stopBroadcast();

        return NetworkConfig({
            initialOwner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            feeAddress: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            tokenAddress: address(token)
        });
    }
}
