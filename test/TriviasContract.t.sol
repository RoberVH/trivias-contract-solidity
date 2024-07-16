// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TriviasContract.sol";
import "forge-std/console.sol";

contract TriviasContractTest is Test {
    TriviasContract public triviasContract;
    address public owner;
    address public user1;
    address public user2;
    uint256 constant ONE_DAYPLUS = 90000;
    uint8 constant TOKENS_GRANT = 10;
    uint256 private constant TOKEN_UNIT = 1e18; // 10 ** 18; // for efficiency on tokens operations
    uint256 private constant INITIAL_SUPPLY = 500000 * TOKEN_UNIT;

    function setUp() public {
        owner = address(this);
        owner = makeAddr("owner"); // Crear una dirección separada para el owner
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Asignar saldo al owner
        vm.deal(owner, 100 ether);

        // Desplegar el contrato como owner y darle 10 ethers de saldo inicial
        vm.startPrank(owner);
        triviasContract = new TriviasContract("TriviaToken", "TRV");
        vm.deal(address(triviasContract), 10 ether);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(triviasContract.name(), "TriviaToken");
        assertEq(triviasContract.symbol(), "TRV");
        assertEq(triviasContract.getTotalSupply(), INITIAL_SUPPLY);
    }

    function testGiveFaucet() public {
        uint256 initialBalance = address(triviasContract).balance;
        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        assertEq(user1.balance, 0.001 ether);
        assertEq(
            address(triviasContract).balance,
            initialBalance - 0.001 ether
        );
    }

    function testAllowFaucetAfterOneDayPassed() public {
        uint256 initialBalance = address(triviasContract).balance;
        console.log("Bal Inicial");
        console.log(initialBalance);

        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        assertEq(user1.balance, 0.001 ether);
        assertEq(
            address(triviasContract).balance,
            initialBalance - 0.001 ether
        );

        // Simulate a day has passed (more than 86400 seconds)
        vm.warp(block.timestamp + ONE_DAYPLUS);

        // try again to get faucet
        uint256 secondBalance = address(triviasContract).balance;
        console.log("secondBalance");
        console.log(secondBalance);
        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        // Verify user  received another 0.001 ether
        assertEq(user1.balance, 0.002 ether);
        assertEq(
            address(triviasContract).balance,
            initialBalance - 0.002 ether
        );
    }

    function testDenyFaucetifNotADaypassed() public {
        uint256 initialBalance = address(triviasContract).balance;
        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        assertEq(user1.balance, 0.001 ether);
        assertEq(
            address(triviasContract).balance,
            initialBalance - 0.001 ether
        );
        // try again to get faucet
        vm.prank(owner);
        vm.expectRevert(TriviasContract.NoEnoughTimePassed.selector);
        triviasContract.giveFaucet(user1);
    }

    function testGiveFaucetOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(TriviasContract.NotOwner.selector);
        triviasContract.giveFaucet(user2);
    }

    function testNoBalanceOnContract() public {
        vm.prank(owner);
        TriviasContract trivias2 = new TriviasContract("TriviaToken1", "TRV2");
        uint256 balance = address(trivias2).balance;
        console.log('balance trivias2');
        console.log(balance);
        vm.startPrank(owner);
        vm.expectRevert(TriviasContract.NoEnoughBalanceInContract.selector);
        trivias2.giveFaucet(user1);
        vm.stopPrank();
    }

    function testNoMoreTokens() public {
        vm.prank(address(triviasContract));
        triviasContract.transfer(user1, INITIAL_SUPPLY);
        assertEq(triviasContract.balanceOf(user1), INITIAL_SUPPLY);
        assertEq(triviasContract.balanceOf(address(triviasContract)), 0);
        // now triviasCOntract tokens balance is zero
        vm.prank(user1);
        vm.expectRevert();
        triviasContract.checkAnswer(0, "0CACBB");
    }

    function testCheckAnswer() public {
        //string[] memory correctAnswer = new string[](5);
        string memory correctAnswer = "0CACBB";

        vm.prank(user1);
        bool result = triviasContract.checkAnswer(0, correctAnswer);
        assertTrue(result);
        assertEq(triviasContract.balanceOf(user1), TOKENS_GRANT * TOKEN_UNIT);
    }

    function testAllAnswers() public {
        checkAnswer(user1, 0, "0CACBB", 1 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 1, "1ADADB", 2 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 2, "2ABBBA", 3 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 3, "3CBCBC", 4 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 4, "4BBCCA", 5 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 5, "5BBCCA", 6 * TOKENS_GRANT * TOKEN_UNIT);
    }

    function testCheckAnswerIncorrect() public {
        //string[] memory incorrectAnswer = new string[](5);
        string memory incorrectAnswer = "0AACBB";

        vm.prank(user1);
        bool result = triviasContract.checkAnswer(0, incorrectAnswer);
        assertFalse(result);
        assertEq(triviasContract.balanceOf(user1), 0);
    }

    function testTokenTransfer() public {
        string memory correctAnswer = "0CACBB";
        // first get some tokens
        vm.prank(user1);
        bool result = triviasContract.checkAnswer(0, correctAnswer);
        assertTrue(result);
        assertEq(triviasContract.balanceOf(user1), TOKENS_GRANT * TOKEN_UNIT);
        vm.prank(user1);
        bool transferResult = triviasContract.transfer(
            user2,
            TOKENS_GRANT * TOKEN_UNIT
        );
        assertTrue(transferResult);
        // Verificar los saldos después de la transferencia
        assertEq(triviasContract.balanceOf(user1), 0);
        assertEq(triviasContract.balanceOf(user2), TOKENS_GRANT * TOKEN_UNIT);
    }

    // function testDecimals() public view {
    //     console.log(triviasContract.getDecimals());
    // }

    function testCannotSolveSameTriviaAgain() public {
        string memory correctAnswer = "0CACBB";
        vm.startPrank(user1);
        triviasContract.checkAnswer(0, correctAnswer);
        vm.expectRevert(TriviasContract.TriviaAlreadySolved.selector);
        triviasContract.checkAnswer(0, correctAnswer);
        vm.stopPrank();
    }

    function testGetterUserSolvedTrivias() public {
        answerAllTrivias(user1);
        uint8[] memory triviasSolved = triviasContract.getUserSolvedTrivias(
            user1
        );
        uint8[] memory expectedTrivias = new uint8[](5);
        expectedTrivias[0] = 0;
        expectedTrivias[1] = 1;
        expectedTrivias[2] = 3;
        expectedTrivias[3] = 4;
        expectedTrivias[4] = 5;
        assertEq(
            triviasSolved.length,
            expectedTrivias.length,
            "Array lengths do not match"
        );
        for (uint i = 0; i < expectedTrivias.length; i++) {
            assertEq(triviasSolved[i], expectedTrivias[i]);
        }
    }

    function answerAllTrivias(address userAddress) private {
        checkAnswer(userAddress, 0, "0CACBB", 1 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(userAddress, 1, "1ADADB", 2 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(userAddress, 3, "3CBCBC", 3 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(userAddress, 4, "4BBCCA", 4 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(userAddress, 5, "5BBCCA", 5 * TOKENS_GRANT * TOKEN_UNIT);
    }

    function checkAnswer(
        address user,
        uint8 triviaIndex,
        string memory correctAnswer,
        uint256 expectedBalance
    ) private {
        vm.prank(user);
        bool result = triviasContract.checkAnswer(triviaIndex, correctAnswer);
        assertTrue(result);
        assertEq(triviasContract.balanceOf(user), expectedBalance);
    }

    function testWithdraw() public {
        uint256 initialContractBalance = address(triviasContract).balance;
        uint256 initialOwnerBalance = owner.balance;

        vm.prank(owner);
        triviasContract.withdraw();

        assertEq(address(triviasContract).balance, 0);
        assertEq(owner.balance, initialOwnerBalance + initialContractBalance);
    }

    function testDeactivate() public {
        vm.prank(owner);
        triviasContract.deactivate();

        // string[] memory answer = new string[](5);
        string memory answer = "0CACBB";
        vm.prank(user1);
        vm.expectRevert(TriviasContract.ContractInactive.selector);
        triviasContract.checkAnswer(0, answer);
    }

    receive() external payable {}
}
