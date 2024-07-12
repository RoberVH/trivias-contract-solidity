// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TriviasContract.sol"; // Asegúrate de que la ruta sea correcta


contract TriviasContractTest is Test {
    TriviasContract public triviasContract;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
     owner = address(this);
        owner = makeAddr("owner");  // Crear una dirección separada para el owner
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
    }

function testGiveFaucet() public {
    uint256 initialBalance = address(triviasContract).balance;
    vm.prank(owner);
    triviasContract.giveFaucet(user1);
    assertEq(user1.balance, 0.001 ether);
    assertEq(address(triviasContract).balance, initialBalance - 0.001 ether);
}

    function testGiveFaucetOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(TriviasContract.NotOwner.selector);
        triviasContract.giveFaucet(user2);
    }

    function testCheckAnswer() public {
        //string[] memory correctAnswer = new string[](5);
        string memory correctAnswer = '0CACBB';
        // correctAnswer[0] = "C";
        // correctAnswer[1] = "A";
        // correctAnswer[2] = "C";
        // correctAnswer[3] = "B";
        // correctAnswer[4] = "B";

        vm.prank(user1);
        bool result = triviasContract.checkAnswer(0, correctAnswer);
        assertTrue(result);
        assertEq(triviasContract.balanceOf(user1), 10);
    }

    function testCheckAnswerIncorrect() public {
        //string[] memory incorrectAnswer = new string[](5);
        string memory incorrectAnswer = '0AACBB';

        // incorrectAnswer[0] = "A";
        // incorrectAnswer[1] = "A";
        // incorrectAnswer[2] = "A";
        // incorrectAnswer[3] = "A";
        // incorrectAnswer[4] = "A";

        vm.prank(user1);
        bool result = triviasContract.checkAnswer(0, incorrectAnswer);
        assertFalse(result);
        assertEq(triviasContract.balanceOf(user1), 0);
    }

    function testCannotSolveSameTriviaAgain() public {
//        string[] memory correctAnswer = new string[](5);
        string memory correctAnswer = '0CACBB';
        // correctAnswer[0] = "C";
        // correctAnswer[1] = "A";
        // correctAnswer[2] = "C";
        // correctAnswer[3] = "B";
        // correctAnswer[4] = "B";

        vm.startPrank(user1);
        triviasContract.checkAnswer(0, correctAnswer);
        vm.expectRevert(TriviasContract.TriviaAlreadySolved.selector);
        triviasContract.checkAnswer(0, correctAnswer);
        vm.stopPrank();
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
         string memory answer = '0CACBB';
        vm.prank(user1);
        vm.expectRevert(TriviasContract.ContractInactive.selector);
        triviasContract.checkAnswer(0, answer);
    }

    receive() external payable {}
}
