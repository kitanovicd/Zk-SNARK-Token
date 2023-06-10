// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ZkSNARKToken} from "src/ZkSNARKToken.sol";
import {Verifier, Pairing} from "src/Verifier.sol";
import {Constants} from "src/Constants.sol";

contract ContractBTest is Test {
    address private alice;
    address private bob;
    ZkSNARKToken private zkSNARKToken;

    function setUp() public {
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        address[] memory initialHolders = new address[](2);
        initialHolders[0] = alice;
        initialHolders[1] = bob;

        Verifier verifier = new Verifier();

        zkSNARKToken = new ZkSNARKToken(
            verifier,
            "ZkSNARKToken",
            "ZkT",
            initialHolders
        );
    }

    function testSetUp() public {
        assertEq(zkSNARKToken.name(), "ZkSNARKToken");
        assertEq(zkSNARKToken.symbol(), "ZkT");
        assertEq(
            zkSNARKToken.hashBalances(alice),
            Constants.INITIAL_SUPPLY_PER_HOLDERS
        );
        assertEq(
            zkSNARKToken.hashBalances(bob),
            Constants.INITIAL_SUPPLY_PER_HOLDERS
        );
    }

    function testTransfer() public {
        vm.startPrank(bob);

        Verifier.Proof memory proof = Verifier.Proof(
            Pairing.G1Point(
                0x1dbc05b0c947a3b59d5fda4018827094fc18e45dde8471e6d98d102051d99522,
                0x11793c70ce4fd1d1001153341f5255e835d86ab40c7ac55fb593963f72a54568
            ),
            Pairing.G2Point(
                [
                    0x0a43d2cee9aefe9f4117e25ea5082c57244a9e58a66abd94cf7256080de320e3,
                    0x1f0737cb6290379db6ee1c3a6ef97efe65433d9914c7c88d6ed46acb70ceddfb
                ],
                [
                    0x10d89117b0002bf74ae2827ae45edbb40ba0d4d775f401cd7fc67b385b7b37d1,
                    0x0c4d58d0a78a06314d4153f149d96c0b1279924578a4c3f55676d811d54fd92a
                ]
            ),
            Pairing.G1Point(
                0x29f3e0b99ad851ac573237539409af0d80c07145ad38fbb71a9558f0f965b6fd,
                0x1f2f80c81446b03eb58224173fa20b0a1f63037bdaf12a6ae7fb6a5b5430bc7f
            )
        );

        //Bob sends everything to Alice
        zkSNARKToken.transfer(
            alice,
            proof,
            [
                uint256(
                    0x00000000000000000000000000000000c2e402cf88bcbe6ab09f882ebe79276b
                ),
                uint256(
                    0x00000000000000000000000000000000c2e402cf88bcbe6ab09f882ebe79276b
                ),
                uint256(
                    0x00000000000000000000000000000000c2e402cf88bcbe6ab09f882ebe79276b
                ),
                uint256(
                    0x00000000000000000000000000000000f5a5fd42d16a20302798ef6ed309979b
                ),
                uint256(
                    0x00000000000000000000000000000000b50a6a432fcb4d7254ac3fc08338b631
                ),
                uint256(
                    0x0000000000000000000000000000000000000000000000000000000000000001
                )
            ]
        );

        //This is the hash of the balances after the transfer
        //Alice has 200 and Bob has 0
        assertEq(
            zkSNARKToken.hashBalances(bob),
            0x00000000000000000000000000000000f5a5fd42d16a20302798ef6ed309979b
        );
        assertEq(
            zkSNARKToken.hashBalances(alice),
            0x00000000000000000000000000000000b50a6a432fcb4d7254ac3fc08338b631
        );

        vm.stopPrank();
    }
}
