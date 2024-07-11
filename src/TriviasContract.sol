// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title TriviasContract 
 *          Implements a contract for crypto-ts-app App. This is intended for the course Intro a la Blockchain for Retailing University
 *          July, 2024
 * @author Roberto Vicuña
 * @notice 
 */


contract TriviasContract {
    
    error NotOwner();
    error NoEnoughTimePassed();
    error NoEnoughBalanceInContract();
    error NoBalanceTowithdraw();
    error ContractInactive();

    event Transfer(address indexed recipient, uint256 amount);

    uint256 public immutable i_oneDay;     
    address private owner;
    bool private active;

    mapping(address => uint256) private FaucetRegistry;
    struct  solutionSchema {
        uint8 triviaIdx;
        string[5] answers;
    }
    
    string[5][6] private solutions;

     modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Allow Deactivation of contract
    modifier whenActive() {
        if (!active) 
        revert ContractInactive();
        _;
    }

    constructor() {
        owner=msg.sender;
        solutions[0] = ["C", "A", "C", "B", "B"];
        solutions[1] = ["A", "D", "A", "D", "B"];
        solutions[2] = ["A", "B", "B", "B", "A"];
        solutions[3] = ["C", "B", "C", "B", "C"];
        solutions[4] = ["B", "B", "C", "C", "A"];
        solutions[5] = ["B", "B", "C", "C", "A"];
        i_oneDay = 86400;   // 1 day in Unix epoch
        active = true;
    }

    function giveFaucet(address _userAddress) external onlyOwner whenActive  {
        if (FaucetRegistry[_userAddress] == 0) {
            // new user
            FaucetRegistry[_userAddress] = block.timestamp;
            transferCrypto(payable(_userAddress));
        } else {
            // recurrent user, check time restriction (1 day has to have passed to request more crypto)
            if (FaucetRegistry[_userAddress] > (block.timestamp +  i_oneDay)) {
                // ok renew to current time the time restriction and transfer the crypto
                FaucetRegistry[_userAddress] = block.timestamp;
                transferCrypto(payable(_userAddress));
            } else {
                revert NoEnoughTimePassed();
            }
        }
    }

    function transferCrypto(address payable recipient)  private whenActive  {
        if (address(this).balance <= 0.001 ether) {
            revert NoEnoughBalanceInContract();
        } else {
            recipient.transfer(0.001 ether);
            emit Transfer(recipient, 0.001 ether);
            }
    }

    function checkAnswer(uint8 indexTrivia,  string[] memory solution) external view onlyOwner whenActive returns (bool) {
        for(uint8 i=0; i<=4; i++ ) {
           if (keccak256(abi.encodePacked(solution[i])) != keccak256(abi.encodePacked(solutions[indexTrivia][i]))) {
                return false;
            }
        }
        return true;
    }

    // Make this contract able to receive ether
    receive() external payable{}
    
    // In case a transacction without data is receive, get the crypto
    fallback() external payable {}

    // to withdraw contract's balance in case owner deprecate it
    function withdraw() external onlyOwner {
   uint256 balance = address(this).balance;
        if(balance > 0) {
            revert NoBalanceTowithdraw();
        }

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // When/if contract is retired 
   function deactivate() external onlyOwner {
        active = false;
    }

   }
