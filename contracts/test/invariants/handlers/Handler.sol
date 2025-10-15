// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FlameStarters} from "../../../src/FlameStarters.sol";
import {ERC20Token} from "../../../src/ERC20Token.sol";

struct AddressSet {
    address[] addrs;
    mapping(address => bool) saved;
}

library LibAddressSet {
    function rand(AddressSet storage s, uint256 seed) internal view returns (address) {
        if (s.addrs.length > 0) {
            return s.addrs[seed % s.addrs.length];
        } else {
            return address(0xc0ffee);
        }
    }

    function add(AddressSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addrs.push(addr);
            s.saved[addr] = true;
        }
    }

    function contains(AddressSet storage s, address addr) internal view returns (bool) {
        return s.saved[addr];
    }

    function count(AddressSet storage s) internal view returns (uint256) {
        return s.addrs.length;
    }

    function getAddressAtIndex(AddressSet storage s, uint256 index) public view returns (address) {
        return s.addrs[index];
    }
}

contract Handler is CommonBase, StdCheats, StdUtils, Test {
    using LibAddressSet for AddressSet;

    AddressSet internal _actors;
    address internal currentActor;

    uint256 constant MAX_SUPPLY = 177;
    uint256 constant FUZZ_FEE = 100 ether;
    uint256 constant FUZZ_ETH_FEE = 0.00001 ether;

    FlameStarters nfts;
    ERC20Token token;
    mapping(bytes32 => uint256) public calls;

    error GiveETHFailed(address sender, address receiver, uint256 amount);

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    function _giveETH(address account, uint256 amount) public {
        (bool success,) = payable(account).call{value: amount}("");
        if (!success) {
            console.log("Contract balance: ", address(this).balance);
            revert GiveETHFailed(address(this), account, amount);
        }
    }

    function getFuzzFee() public pure returns (uint256) {
        return FUZZ_FEE;
    }

    function getFuzzEthFee() public pure returns (uint256) {
        return FUZZ_ETH_FEE;
    }

    constructor(FlameStarters _nfts, ERC20Token _token) {
        nfts = _nfts;
        token = _token;

        address owner = token.owner();
        uint256 balance = token.balanceOf(owner);

        // fund handler
        vm.prank(owner);
        token.transfer(address(this), balance);
        deal(address(this), 5000 ether);

        // setup nft contract
        vm.startPrank(nfts.owner());
        nfts.setMaxPerWallet(177);
        nfts.setBatchLimit(100);
        nfts.setTokenFee(FUZZ_FEE);
        nfts.setEthFee(FUZZ_ETH_FEE);
        vm.stopPrank();

        // pre-approve tokens
        token.approve(address(nfts), balance);
    }

    receive() external payable {}

    fallback() external payable {}

    function mintNfts(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("mint") {
        _actors.add(msg.sender);
        amount = bound(amount, 1, 5);

        uint256 totalEthFee = amount * FUZZ_ETH_FEE;
        uint256 totalFee = amount * FUZZ_FEE;
        token.transfer(currentActor, totalFee);
        deal(currentActor, totalEthFee);

        vm.startPrank(currentActor);
        token.approve(address(nfts), totalFee);
        nfts.mint{value: totalEthFee}(amount);
        vm.stopPrank();
    }

    function callSummary() external view {
        console.log("\nCall summary:");
        console.log("-------------------");
        console.log("mint", calls["mint"]);
        console.log("transfer", calls["transfer"]);
    }
}
