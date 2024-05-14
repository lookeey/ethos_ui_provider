// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {ICollateralConfig} from "./interfaces/ICollateralConfig.sol";
import {ICollSurplusPool} from "./interfaces/ICollSurplusPool.sol";
import {ITroveManager} from "./interfaces/ITroveManager.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";
import {IActivePool} from "./interfaces/IActivePool.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract EthosDataAggregator {
    // Data structs
    struct CollData {
        address collateral;
        uint256 minCollateralRatio;
        uint256 criticalCollateralRatio;
        uint256 price;
        uint256 totalCollateralRatio;
        uint256 entireSystemCollateral;
        uint256 entireSystemDebt;
        uint256 decimals;
        uint256 priceDecimals;
        address yieldGenerator;
    }

    struct GlobalData {
        uint256 liquidationReserve;
        uint256 minNetDebt;
        uint256 borrowingRate;
    }

    struct UserCollData {
        address collateral;
        uint256 troveStatus;
        uint256 troveDebt;
        uint256 troveCollDeposited;
        uint256 claimableColl;
    }

    function getGlobalData(ICollSurplusPool collSurplusPool, ICollateralConfig collateralConfig, IPriceFeed priceFeed, ITroveManager troveManager)
        external
        view
        returns (GlobalData memory, CollData[] memory)
    {
        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();
        CollData[] memory collateralData = new CollData[](collAddrs.length);
        for (uint256 i = 0; i < collAddrs.length; i++) {
            address collAddr = collAddrs[i];
            (int256 price, uint256 priceDecimals) = tryFetchPrice(collAddr, priceFeed);
            IActivePool activePool = IActivePool(collSurplusPool.activePoolAddress());

            uint256 fixedDecimalsPrice;
            if (priceDecimals > 18) {
                fixedDecimalsPrice = uint256(price) / (10 ** (priceDecimals - 18));
            } else {
                fixedDecimalsPrice = uint256(price) * (10 ** (18 - priceDecimals));
            }

            collateralData[i] = CollData({
                collateral: collAddr,
                minCollateralRatio: collateralConfig.getCollateralMCR(collAddr),
                criticalCollateralRatio: collateralConfig.getCollateralCCR(collAddr),
                price: uint256(fixedDecimalsPrice),
                totalCollateralRatio: troveManager.getTCR(collAddr, uint256(price)),
                entireSystemCollateral: troveManager.getEntireSystemColl(collAddr),
                entireSystemDebt: troveManager.getEntireSystemDebt(collAddr),
                yieldGenerator: activePool.yieldGenerator(collAddr),
                priceDecimals: priceDecimals,
                decimals: collateralConfig.getCollateralDecimals(collAddr)
            });
        }

        GlobalData memory globalData = GlobalData({
            liquidationReserve: troveManager.LUSD_GAS_COMPENSATION(),
            minNetDebt: troveManager.MIN_NET_DEBT(),
            borrowingRate: troveManager.getBorrowingRateWithDecay()
        });

        return (globalData, collateralData);
    }

    function getUserData(address _user, ICollSurplusPool collSurplusPool, ICollateralConfig collateralConfig, ITroveManager troveManager) external view returns (UserCollData[] memory) {
        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();

        UserCollData[] memory userCollData = new UserCollData[](collAddrs.length);
        for (uint256 i = 0; i < collAddrs.length; i++) {
            address collAddr = collAddrs[i];
            userCollData[i] = UserCollData({
                collateral: collAddr,
                troveStatus: troveManager.getTroveStatus(_user, collAddr),
                troveDebt: troveManager.getTroveDebt(_user, collAddr),
                troveCollDeposited: troveManager.getTroveColl(_user, collAddr),
                claimableColl: collSurplusPool.getUserCollateral(_user, collAddr)
            });
        }
        return userCollData;
    }

    function tryFetchPrice(address _collateral, IPriceFeed _priceFeed)
        public
        view
        returns (int256 price, uint256 aggrDecimals)
    {
        IAggregatorV3 priceAggregator = _priceFeed.priceAggregator(_collateral);
        aggrDecimals = priceAggregator.decimals();
        (bool success, bytes memory data) =
            address(priceAggregator).staticcall(abi.encodeWithSelector(priceAggregator.latestAnswer.selector));
        if (success) {
            (price) = abi.decode(data, (int256));
            return (price, aggrDecimals);
        }
        (, price,,,) = priceAggregator.latestRoundData();
        return (price, aggrDecimals);
    }
}
