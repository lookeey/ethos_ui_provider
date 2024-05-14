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
        EthosDataAggregator.Addresses[] memory addresses = abi.decode(
            vm.parseJson(configs, string.concat(deployment, ".versions")),
            (EthosDataAggregator.Addresses[])
        );

        vm.broadcast();

        console.log("Deploying EthosDataAggregator with the following addresses:");
        /* console.log("PriceFeed: %s", cfg.priceFeed);
        console.log("CollateralConfig: %s", cfg.collateralConfig);
        console.log("CollSurplusPool: %s", cfg.collSurplusPool);
        console.log("TroveManager: %s", cfg.troveManager); */
        for (uint256 i = 0; i < addresses.length; i++) {
            console.log("Version: %s", i);
            console.log("PriceFeed: %s", addresses[i].priceFeed);
            console.log("CollateralConfig: %s", addresses[i].collateralConfig);
            console.log("CollSurplusPool: %s", addresses[i].collSurplusPool);
            console.log("TroveManager: %s", addresses[i].troveManager);
        }

        EthosDataAggregator aggregator = new EthosDataAggregator(
            addresses
        );

        console.log("Aggregator deployed at: %s", address(aggregator));
    }
}
