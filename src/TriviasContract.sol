// SPDX-License-Identifier: MIT

/**
 * @title TriviasContract 
 *          Implements a contract for crypto-ts-app App. This is intended for the course Intro a la Blockchain for Retailing University
 *          July, 2024
 * @author Roberto Vicuña
 * @notice 
 */
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";

contract TriviasContract is ERC20{
    
    error NotOwner();
    error NoEnoughTimePassed();
    error NoEnoughBalanceInContract();
    error NoBalanceTowithdraw();
    error ContractInactive();
    error TriviaAlreadySolved();

    event Transfer(address indexed recipient, uint256 amount);

    uint8 constant  NUMBER_ANSWERS=5; // number of asnwers for each trivia
    uint8 constant  NUMBER_TRIVIAS=5; // number of  trivias
    uint256 constant  FAUCET_GRANT=0.001 ether; // Ethereums to send from Faucet contrat
    uint8 constant  TOKENS_GRANT=10; // Number of contracts tokens to grant on each correctlye trivia answered


    uint256 public immutable i_oneDay;     
    address private owner;
    bool private active;

    mapping(address => uint256) private FaucetRegistry;
    struct  solutionSchema {
        uint8 triviaIdx;
        string[5] answers;
    }
    
    string[5][6] private solutions;
    string[6] private solutionsHash;

    // keep track of which trivias has the address  solved
    mapping(address => uint8[]) private solvedTrivias;

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

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner=msg.sender;
        solutions[0] = ["C", "A", "C", "B", "B"]; solutionsHash[0] ="0x9598dbcbd83ef19c37403e5502aafc4eb365e222df5d75c53c17fe22f6822bee";
        solutions[1] = ["A", "D", "A", "D", "B"]; solutionsHash[1] ="0x04cf229431d921cec0b67ec82d5d0c6bd49f826b62665ebd201eb9562a33fde0";
        solutions[2] = ["A", "B", "B", "B", "A"]; solutionsHash[2] ="0x02f9a28b2ddc736cac90e57e8bcc6fe5b38588b5737b9de41516826b6fa3d8a8";
        solutions[3] = ["C", "B", "C", "B", "C"]; solutionsHash[3] ="0xee1421cb94aeddf0678f494295468373d934c53bd3ccf5b2adcd17603b720c9b";
        solutions[4] = ["B", "B", "C", "C", "A"]; solutionsHash[4] ="0x7edb8cbb43220aabf89e76e0527679bdf7d7e86df257082e57a02e83803e720f";
        solutions[5] = ["B", "B", "C", "C", "A"]; solutionsHash[5] ="0x480eeff190b1da1d3fc451596c9f086abef656466ac7cf84b302442f16fe7216";

        i_oneDay = 86400;   // 1 day in Unix epoch
        active = true;
    }

    // Function to mint tokens ERC-20
    // is called when user has answered correctly a trivia
    function mint(address to, uint256 amount) private  {
        _mint(to, amount);
    }

      // Function to check the ERC-20 balance of a specific account
    //function balanceOf(address account) public view override returns (uint256) {
     //   return super.balanceOf(account);
   // }

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

// user send answers array of indexTrivia trivia to check if correct. 
// if correct and hasn't been answered before, grant 10 tokes and register it's been answered
    //function checkAnswer(uint8 indexTrivia,  string[] memory solution) external whenActive returns (bool) {
    function checkAnswer(uint8 indexTrivia,  string memory solution) external whenActive returns (bool) {
        console.log('hash del param recibido',keccak256(abi.encodePacked(solution)));
        console.log('bytes de sol almacenada', stringToBytes32(solutionsHash[indexTrivia]));
        // for(uint8 i=0; i < NUMBER_ANSWERS; i++ ) {
           //if (keccak256(abi.encodePacked(solution[i])) != keccak256(abi.encodePacked(solutions[indexTrivia][i]))) {
           if (keccak256(abi.encodePacked(solution)) != stringToBytes32(solutionsHash[indexTrivia])) {
                return false;
            }
        // }
        uint8[] memory userSolvedTrivias = solvedTrivias[msg.sender];
        uint8 totalSolved = uint8(userSolvedTrivias.length);
        for (uint8 i=0; i< totalSolved; i++) {
            if (userSolvedTrivias[i]==indexTrivia) {
                revert TriviaAlreadySolved();
            }
        }
        solvedTrivias[msg.sender].push(indexTrivia);
        mint(msg.sender,TOKENS_GRANT); // grant 10 tokens for each correctly asnwered trivia
        return true;
    }

    // Make this contract able to receive ether
    receive() external payable{}
    
    // In case a transacction without data is receive, get the crypto
    fallback() external payable {}

    // to withdraw contract's balance in case owner deprecate it
    function withdraw() external onlyOwner {
   uint256 balance = address(this).balance;
        if(!(balance > 0)) {
            revert NoBalanceTowithdraw();
        }

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // When/if contract is retired 
   function deactivate() external onlyOwner {
        active = false;
    }

 function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

   }
