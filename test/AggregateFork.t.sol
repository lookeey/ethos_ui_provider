// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EthosDataAggregator} from "src/EthosDataAggregator.sol";

contract AggregatorForkTest is Test {
    EthosDataAggregator aggregator;

    string configs;

    function setUp() public {
        configs = vm.readFile("./test/deployments.json");
    }

    function getGlobalData(string memory deployment, uint version) internal {
        // Config memory cfg = abi.decode(vm.parseJson(configs, deployment), (Config));

        EthosDataAggregator.Addresses[] memory addresses = abi.decode(
            vm.parseJson(configs, string.concat(deployment, ".versions")),
            (EthosDataAggregator.Addresses[])
        );

        aggregator = new EthosDataAggregator(
            /* cfg.priceFeed, cfg.collateralConfig, cfg.collSurplusPool, cfg.troveManager */
            addresses
        );
        
        aggregator.addAddresses(addresses[0]);

        (EthosDataAggregator.GlobalData memory globalData, EthosDataAggregator.CollData[] memory collData) =
            aggregator.getGlobalData(version);

        console.log("Collateral Data:");
        for (uint256 i = 0; i < collData.length; i++) {
            console.log("Collateral %s", collData[i].collateral);
            console.log("Min Collateral Ratio: %s", collData[i].minCollateralRatio);
            console.log("Critical Collateral Ratio: %s", collData[i].criticalCollateralRatio);
            console.log("Price: %s", collData[i].price);
            console.log("Total Collateral Ratio: %s", collData[i].totalCollateralRatio);
            console.log("Entire System Collateral: %s", collData[i].entireSystemCollateral);
            console.log("Entire System Debt: %s", collData[i].entireSystemDebt);
            console.log("");
        }

        console.log("Global Data:");
        console.log("Liquidation Reserve: %s", globalData.liquidationReserve);
        console.log("Min Net Debt: %s", globalData.minNetDebt);
        console.log("Borrowing Rate: %s", globalData.borrowingRate);
    }

    function getUserData(string memory deployment, uint version) internal {
        EthosDataAggregator.Addresses[] memory addresses = abi.decode(
            vm.parseJson(configs, string.concat(deployment, ".versions")),
            (EthosDataAggregator.Addresses[])
        );

        aggregator = new EthosDataAggregator(
            /* cfg.priceFeed, cfg.collateralConfig, cfg.collSurplusPool, cfg.troveManager */
            addresses
        );

        address user = abi.decode(vm.parseJson(configs, string.concat(deployment, ".testUser")), (address));

        (EthosDataAggregator.UserCollData[] memory userData) = aggregator.getUserData(user, version);

        console.log("User Data:");
        for (uint256 i = 0; i < userData.length; i++) {
            console.log("Collateral %s", userData[i].collateral);
            console.log("Trove Status: %s", userData[i].troveStatus);
            console.log("Trove Debt: %s", userData[i].troveDebt);
            console.log("Trove Collateral Deposited: %s", userData[i].troveCollDeposited);
            console.log("Claimable Collateral: %s", userData[i].claimableColl);
            console.log("");
        }
    }

    function test_aurelius() public {
        vm.createSelectFork("mantle");
        getGlobalData(".aurelius", 0);
        getUserData(".aurelius", 0);
    }

    function test_ethosv1() public {
        vm.createSelectFork("optimism");
        getGlobalData(".ethos", 0);
        getUserData(".ethos", 0);
    }

    function test_ethosv2() public {
        vm.createSelectFork("optimism");
        getGlobalData(".ethos", 1);
        getUserData(".ethos", 1);
    }

    function test_ethosv2_1() public {
        vm.createSelectFork("optimism");
        getGlobalData(".ethos", 2);
        getUserData(".ethos", 2);
    }
}
