// SPDX-License-Identifier: MIT
/**
 * @title DeployTriviaContract.s.sol
 * @author R.V.
 * @notice Comando to deploy contract TriviaContract:
 *              forge script script/DeployTriviaContract.s.sol:DeployTriviaContract --rpc-url $ALCHEMY_SEPOLIA_URL --private-key $PRIVATE_KEY --broadcast
 *              Environment Vars have to be set up prior to run it
 */

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TriviasContract.sol";

contract DeployTriviasContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TriviasContract triviasContract = new TriviasContract(
            "TriviaTokens",
            "TTS"
        );

        vm.stopBroadcast();

        console.log("TriviasContract deployed at:", address(triviasContract));
    }
}
