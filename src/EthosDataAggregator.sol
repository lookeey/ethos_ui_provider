// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {ICollateralConfig} from "./interfaces/ICollateralConfig.sol";
import {ICollSurplusPool} from "./interfaces/ICollSurplusPool.sol";
import {ITroveManager} from "./interfaces/ITroveManager.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";
import {IActivePool} from "./interfaces/IActivePool.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract EthosDataAggregator is Ownable {
    // Storage Structs
    struct Addresses {
        address collSurplusPool;
        address collateralConfig;
        address priceFeed;
        address troveManager;
    }

    // Data structs
    struct CollData {
        address collateral;
        uint minCollateralRatio;
        uint criticalCollateralRatio;
        uint price;
        uint totalCollateralRatio;
        uint entireSystemCollateral;
        uint entireSystemDebt;
        uint decimals;
        uint priceDecimals;
        address yieldGenerator;
    }

    struct GlobalData {
        uint liquidationReserve;
        uint minNetDebt;
        uint borrowingRate;
    }

    struct UserCollData {
        address collateral;
        uint troveStatus;
        uint troveDebt;
        uint troveCollDeposited;
        uint claimableColl;
    }

    Addresses[] public addresses;

    constructor(Addresses[] memory _addresses) Ownable(msg.sender) {
        addresses = _addresses;
    }

    function setAddresses(Addresses[] memory _addresses) external onlyOwner {
        addresses = _addresses;
    }

    function addAddresses(Addresses memory _addresses) external onlyOwner {
        addresses.push(_addresses);
    }

    function getGlobalData(uint version) external view returns (GlobalData memory, CollData[] memory) {
        Addresses memory addrs = addresses[version];
        IPriceFeed priceFeed = IPriceFeed(addrs.priceFeed);
        ICollateralConfig collateralConfig = ICollateralConfig(addrs.collateralConfig);
        ICollSurplusPool collSurplusPool = ICollSurplusPool(addrs.collSurplusPool);
        ITroveManager troveManager = ITroveManager(addrs.troveManager);

        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();
        CollData[] memory collateralData = new CollData[](collAddrs.length);
        for (uint i = 0; i < collAddrs.length; i++) {
            address collAddr = collAddrs[i];
            (int price, uint priceDecimals) = tryFetchPrice(collAddr, priceFeed);
            IActivePool activePool = IActivePool(collSurplusPool.activePoolAddress());

            uint fixedDecimalsPrice;
            if (priceDecimals > 18) {
                fixedDecimalsPrice = uint(price) / (10 ** (priceDecimals - 18));
            } else {
                fixedDecimalsPrice = uint(price) * (10 ** (18 - priceDecimals));
            }

            collateralData[i] = CollData({
                collateral: collAddr,
                minCollateralRatio: collateralConfig.getCollateralMCR(collAddr),
                criticalCollateralRatio: collateralConfig.getCollateralCCR(collAddr),
                price: uint(fixedDecimalsPrice),
                totalCollateralRatio: troveManager.getTCR(collAddr, uint(price)),
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

    function getUserData(address _user, uint version) external view returns (UserCollData[] memory) {
        Addresses memory addrs = addresses[version];
        ICollSurplusPool collSurplusPool = ICollSurplusPool(addrs.collSurplusPool);
        ITroveManager troveManager = ITroveManager(addrs.troveManager);
        ICollateralConfig collateralConfig = ICollateralConfig(addrs.collateralConfig);

        address[] memory collAddrs = collateralConfig.getAllowedCollaterals();

        UserCollData[] memory userCollData = new UserCollData[](collAddrs.length);
        for (uint i = 0; i < collAddrs.length; i++) {
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

    function tryFetchPrice(address _collateral, IPriceFeed _priceFeed) public view returns (int price, uint aggrDecimals) {
        IAggregatorV3 priceAggregator = _priceFeed.priceAggregator(_collateral);
        aggrDecimals = priceAggregator.decimals();
        (bool success, bytes memory data) = address(priceAggregator).staticcall(abi.encodeWithSelector(priceAggregator.latestAnswer.selector));
        if (success) {
            (price) = abi.decode(data, (int));
            return (price, aggrDecimals);
        }
        (, price,,,) = priceAggregator.latestRoundData();
        return (price, aggrDecimals);
    }
}
