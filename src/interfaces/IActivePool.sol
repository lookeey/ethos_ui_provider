pragma solidity ^0.8.13;

interface IActivePool {
    function yieldGenerator(address coll) external view returns (address);
}