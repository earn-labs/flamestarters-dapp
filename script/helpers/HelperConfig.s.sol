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
            activeNetworkConfig = getBscTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getBscTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0xCbA52038BF0814bC586deE7C061D6cb8B203f8e1,
            feeAddress: 0xCbA52038BF0814bC586deE7C061D6cb8B203f8e1,
            tokenAddress: 0xb6347F2A99CB1a431729e9D4F7e946f58E7C35C7
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialOwner: 0x4671a210C4CF44C43dC5E44DAf68e64D46cdc703,
            feeAddress: 0x0cf66382d52C2D6c1D095c536c16c203117E2B2f,
            tokenAddress: 0xEf3B8512196Ab65F8603b82D1FA5a29bb5ADFeD0
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
