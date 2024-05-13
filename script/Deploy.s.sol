// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EthosDataAggregator} from "../src/EthosDataAggregator.sol";

contract DeployScript is Script {
    struct Config {
        string chain;
        address collSurplusPool;
        address collateralConfig;
        address priceFeed;
        address troveManager;
        address user;
    }

    string configs;

    function setUp() public {
        configs = vm.readFile("./test/deployments.json");
    }

    function run(
        string memory deployment
    ) public {
        Config memory cfg = abi.decode(vm.parseJson(configs, deployment), (Config));

        vm.broadcast();

        console.log("Deploying EthosDataAggregator with the following addresses:");
        console.log("PriceFeed: %s", cfg.priceFeed);
        console.log("CollateralConfig: %s", cfg.collateralConfig);
        console.log("CollSurplusPool: %s", cfg.collSurplusPool);
        console.log("TroveManager: %s", cfg.troveManager);

        EthosDataAggregator aggregator = new EthosDataAggregator(
            cfg.priceFeed,
            cfg.collateralConfig,
            cfg.collSurplusPool,
            cfg.troveManager
        );

        console.log("Aggregator deployed at: %s", address(aggregator));
    }
}
