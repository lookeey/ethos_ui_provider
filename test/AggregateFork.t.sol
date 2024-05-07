// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EthosDataAggregator} from "src/EthosDataAggregator.sol";

contract AggregatorForkTest is Test {
    EthosDataAggregator aggregator;

    function test_aurelius() public {
        vm.createSelectFork('mantle');
        aggregator = new EthosDataAggregator(
            0x93A98b20b159cDb8fB2e899D6f5b35371782FaD3,
            0xbeb31b7AB58e1F38b9A99406571c2cd69a23Cf41,
            0x52874ef3Fcc4F8237A7505E2A25b0146440C782e,
            0x295c6074F090f85819cbC911266522e43A8e0f4A
        );

        (EthosDataAggregator.GlobalData memory globalData, EthosDataAggregator.CollData[] memory collData) = aggregator.getGlobalData();

        console.log("Collateral Data:");
        for (uint i = 0; i < collData.length; i++) {
            console.log("Collateral %s", i);
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

    function test_aureliusUser() public {
        vm.createSelectFork('mantle');
        aggregator = new EthosDataAggregator(
            0x93A98b20b159cDb8fB2e899D6f5b35371782FaD3,
            0xbeb31b7AB58e1F38b9A99406571c2cd69a23Cf41,
            0x52874ef3Fcc4F8237A7505E2A25b0146440C782e,
            0x295c6074F090f85819cbC911266522e43A8e0f4A
        );

        (EthosDataAggregator.UserCollData[] memory userData) = aggregator.getUserData(0x31DDDf4E2ac81403FA9b993CfBE4CA535a1656b5);

        console.log("User Data:");
        for (uint i = 0; i < userData.length; i++) {
            console.log("Collateral %s", i);
            console.log("Trove Status: %s", userData[i].troveStatus);
            console.log("Trove Debt: %s", userData[i].troveDebt);
            console.log("Trove Collateral Deposited: %s", userData[i].troveCollDeposited);
            console.log("Claimable Collateral: %s", userData[i].claimableColl);
            console.log("");
        }
    } 
}
