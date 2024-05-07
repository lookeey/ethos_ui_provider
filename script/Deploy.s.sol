// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EthosDataAggregator} from "../src/EthosDataAggregator.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run(
        address _priceFeed,
        address _collateralConfig,
        address _collSurplusPool,
        address _troveManager
    ) public {
        vm.broadcast();

        console.log("Deploying EthosDataAggregator with the following addresses:");
        console.log("PriceFeed: %s", _priceFeed);
        console.log("CollateralConfig: %s", _collateralConfig);
        console.log("CollSurplusPool: %s", _collSurplusPool);
        console.log("TroveManager: %s", _troveManager);

        EthosDataAggregator aggregator = new EthosDataAggregator(
            _priceFeed,
            _collateralConfig,
            _collSurplusPool,
            _troveManager
        );

        console.log("Aggregator deployed at: %s", address(aggregator));
    }
}
