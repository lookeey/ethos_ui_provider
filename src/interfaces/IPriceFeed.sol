// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { IAggregatorV3 } from "./IAggregatorV3.sol";

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(address _collateral, uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice(address _collateral) external returns (uint);
    function updateChainlinkAggregator(
        address _collateral,
        address _priceAggregatorAddress
    ) external;
    function updateTellorQueryID(address _collateral, bytes32 _queryId) external;

    function priceAggregator(address _collateral) external view returns (IAggregatorV3);
}
