// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EthosDataAggregator} from "../src/EthosDataAggregator.sol";

contract DeployScript is Script {
    string configs;

    function setUp() public {
        configs = vm.readFile("./test/deployments.json");
    }

    function run(
        string memory deployment
    ) public {
        vm.startBroadcast();

        EthosDataAggregator aggregator = new EthosDataAggregator();

        vm.stopBroadcast();

        console.log("Aggregator deployed at: %s", address(aggregator));
    }
}
