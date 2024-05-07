// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {ICollateralConfig} from "./interfaces/ICollateralConfig.sol";
import {ICollSurplusPool} from "./interfaces/ICollSurplusPool.sol";
import {ITroveManager} from "./interfaces/ITroveManager.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";

contract EthosDataAggregator {
    IPriceFeed public immutable priceFeed;
    ICollateralConfig public immutable collateralConfig;
    ICollSurplusPool public immutable collSurplusPool;
    ITroveManager public immutable troveManager;

    struct CollData {
        uint minCollateralRatio;
        uint criticalCollateralRatio;
        uint price;
        uint totalCollateralRatio;
        uint entireSystemCollateral;
        uint entireSystemDebt;
    }

    struct GlobalData {
        uint liquidationReserve;
        uint minNetDebt;
        uint borrowingRate;
    }

    struct UserCollData {
        uint troveStatus;
        uint troveDebt;
        uint troveCollDeposited;
        uint claimableColl;
    }

    constructor(
        address _priceFeed,
        address _collateralConfig,
        address _collSurplusPool,
        address _troveManager
    ) {
        priceFeed = IPriceFeed(_priceFeed);
        collateralConfig = ICollateralConfig(_collateralConfig);
        collSurplusPool = ICollSurplusPool(_collSurplusPool);
        troveManager = ITroveManager(_troveManager);
    }

    function getGlobalData() external view returns (CollData[] memory, GlobalData memory) {
        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();
        return _getGlobalData(collAddrs);
    }

    function getUserData(address _user) external view returns (UserCollData[] memory) {
        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();
        return _getUserData(_user, collAddrs);
    }

    function _getGlobalData(address[] memory collAddrs) internal view returns (CollData[] memory, GlobalData memory) {
        CollData[] memory collateralData = new CollData[](collAddrs.length);
        for (uint i = 0; i < collAddrs.length; i++) {
            address collAddr = collAddrs[i];
            IAggregatorV3 priceAggregator = priceFeed.priceAggregator(collAddr);
            (,int price,,,) = priceAggregator.latestRoundData();

            collateralData[i] = CollData({
                minCollateralRatio: collateralConfig.getCollateralMCR(collAddr),
                criticalCollateralRatio: collateralConfig.getCollateralCCR(collAddr),
                price: uint(price),
                totalCollateralRatio: troveManager.getTCR(collAddr, uint(price)),
                entireSystemCollateral: troveManager.getEntireSystemColl(collAddr),
                entireSystemDebt: troveManager.getEntireSystemDebt(collAddr)
            });
        }

        GlobalData memory globalData = GlobalData({
            liquidationReserve: troveManager.LUSD_GAS_COMPENSATION(),
            minNetDebt: troveManager.MIN_NET_DEBT(),
            borrowingRate: troveManager.getBorrowingRateWithDecay()
        });

        return (collateralData, globalData);
    }

    function _getUserData(address _user, address[] memory collAddrs) internal view returns (UserCollData[] memory) {
        UserCollData[] memory userCollData = new UserCollData[](collAddrs.length);
        for (uint i = 0; i < collAddrs.length; i++) {
            address collAddr = collAddrs[i];
            userCollData[i] = UserCollData({
                troveStatus: troveManager.getTroveStatus(_user, collAddr),
                troveDebt: troveManager.getTroveDebt(_user, collAddr),
                troveCollDeposited: troveManager.getTroveColl(_user, collAddr),
                claimableColl: collSurplusPool.getUserCollateral(_user, collAddr)
            });
        }
        return userCollData;
    }
}
