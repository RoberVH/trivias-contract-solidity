// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TriviasContract} from "../src/TriviasContract.sol";

contract CounterTest is Test {
    TriviasContract public triviasContract;

    function setUp() public {
        triviasContract = new TriviasContract();
    }
    
}
