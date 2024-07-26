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
    uint256 private faucetGrant = 0.1 ether; // Ethereums to send from Faucet contrat

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
        assertEq(user1.balance, faucetGrant);
        assertEq(
            address(triviasContract).balance,
            initialBalance - faucetGrant
        );
    }

    function testAllowFaucetAfterOneDayPassed() public {
        uint256 initialBalance = address(triviasContract).balance;

        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        assertEq(user1.balance, faucetGrant);
        assertEq(
            address(triviasContract).balance,
            initialBalance - faucetGrant
        );

        // Simulate a day has passed (more than 86400 seconds)
        vm.warp(block.timestamp + ONE_DAYPLUS);

        // try again to get from faucet
        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        // Verify user  received another faucetGrant
        assertEq(user1.balance, 2 * faucetGrant);
        assertEq(
            address(triviasContract).balance,
            initialBalance - (2 * faucetGrant)
        );
    }

    function testDenyFaucetifNotADaypassed() public {
        uint256 initialBalance = address(triviasContract).balance;
        vm.prank(owner);
        triviasContract.giveFaucet(user1);
        assertEq(user1.balance, faucetGrant);
        assertEq(
            address(triviasContract).balance,
            initialBalance - faucetGrant
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
        triviasContract.scoreAnswer(0, "0CACBB");
    }

    function testCheckAnswer() public {
        //string[] memory correctAnswer = new string[](5);
        string memory correctAnswer = "0BACBB";
        vm.prank(user1);
        triviasContract.scoreAnswer(0, correctAnswer);
        assertEq(triviasContract.balanceOf(user1), TOKENS_GRANT * TOKEN_UNIT);
    }

    function testAllAnswers() public {
        checkAnswer(user1, 0, "0BACBB", 1 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 1, "1ACADB", 2 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 2, "2BBBBA", 3 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 3, "3CBCBC", 4 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 4, "4BBCCA", 5 * TOKENS_GRANT * TOKEN_UNIT);
        checkAnswer(user1, 5, "5BBCCA", 6 * TOKENS_GRANT * TOKEN_UNIT);
    }

    function testCheckAnswerIncorrect() public {
        //string[] memory incorrectAnswer = new string[](5);
        string memory incorrectAnswer = "0AACBB";

        vm.prank(user1);
        vm.expectRevert(TriviasContract.AnsweredIncorrect.selector);
        triviasContract.scoreAnswer(0, incorrectAnswer);
        assertEq(triviasContract.balanceOf(user1), 0);
    }

    function testTokenTransfer() public {
        string memory correctAnswer = "0BACBB";
        // first get some tokens
        vm.prank(user1);
        triviasContract.scoreAnswer(0, correctAnswer);
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
        string memory correctAnswer = "0BACBB";
        vm.startPrank(user1);
        triviasContract.scoreAnswer(0, correctAnswer);
        vm.expectRevert(TriviasContract.TriviaAlreadySolved.selector);
        triviasContract.scoreAnswer(0, correctAnswer);
        vm.stopPrank();
    }

    function testGetterUserSolvedTrivias() public {
        answerAllTrivias(user1);
        uint8[] memory triviasSolved = triviasContract.getUserSolvedTrivias(
            user1
        );
        uint8[] memory expectedTrivias = new uint8[](6);
        expectedTrivias[0] = 0;
        expectedTrivias[1] = 1;
        expectedTrivias[2] = 2;
        expectedTrivias[3] = 3;
        expectedTrivias[4] = 4;
        expectedTrivias[5] = 5;
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
        checkAnswer(userAddress, 0, "0BACBB", 1 * TOKENS_GRANT * TOKEN_UNIT);       // BACBB
        checkAnswer(userAddress, 1, "1ACADB", 2 * TOKENS_GRANT * TOKEN_UNIT);       // ACADB
        checkAnswer(userAddress, 2, "2BBBBA", 3 * TOKENS_GRANT * TOKEN_UNIT);       // BBBBA
        checkAnswer(userAddress, 3, "3CBCBC", 4 * TOKENS_GRANT * TOKEN_UNIT);       // CBCBC
        checkAnswer(userAddress, 4, "4BBCCA", 5 * TOKENS_GRANT * TOKEN_UNIT);       // BBCCA
        checkAnswer(userAddress, 5, "5BBCCA", 6 * TOKENS_GRANT * TOKEN_UNIT);       // BBCCA
    }

    function checkAnswer(
        address user,
        uint8 triviaIndex,
        string memory correctAnswer,
        uint256 expectedBalance
    ) private {
        vm.prank(user);
        triviasContract.scoreAnswer(triviaIndex, correctAnswer);
        assertEq(triviasContract.balanceOf(user), expectedBalance);
    }

    function testFaucetGrantgetter() public {
        vm.prank(owner);
        uint256 granted = triviasContract.getFaucetGrant();
        assertEq(granted, faucetGrant);
    }

    function testFaucetGrantsetter() public {
        vm.prank(owner);
        triviasContract.setFaucetGrant(uint256(0.9 ether));
        uint256 granted = triviasContract.getFaucetGrant();
        assertEq(granted, uint256(0.9 ether));
    }

    function testrefuseNoOwnersetFaucetGrant() public {
        vm.prank(user1);
        vm.expectRevert(TriviasContract.NotOwner.selector);
        triviasContract.setFaucetGrant(uint256(1 ether));
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
        triviasContract.scoreAnswer(0, answer);
    }

    receive() external payable {}
}
