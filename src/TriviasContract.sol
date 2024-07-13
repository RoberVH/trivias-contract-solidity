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
    uint256 constant ONE_DAY=86400;


    uint256 public immutable i_oneDay;     
    address private owner;
    bool private active;

    mapping(address => uint256) private FaucetRegistry;
    struct  solutionSchema {
        uint8 triviaIdx;
        string[5] answers;
    }
    
    string[5][6] private solutions;
    // string[6] private solutionsHash;
    bytes32[6] private solutionsHash;

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
        solutionsHash[0] =0xd8dbc5180fdff1b4d6b9c00750ab421a845f6550c5d7ceac8dc65ea12b601a8b;
        solutionsHash[1] =0x1d5d77da36ac7b28f08eee422f4086c1b300b0153527284c5988a113fe1f0cb2;
        solutionsHash[2] =0x02f9a28b2ddc736cac90e57e8bcc6fe5b38588b5737b9de41516826b6fa3d8a8;
        solutionsHash[3] =0xee1421cb94aeddf0678f494295468373d934c53bd3ccf5b2adcd17603b720c9b;
        solutionsHash[4] =0x7edb8cbb43220aabf89e76e0527679bdf7d7e86df257082e57a02e83803e720f;
        solutionsHash[5] =0x480eeff190b1da1d3fc451596c9f086abef656466ac7cf84b302442f16fe7216;

        i_oneDay = ONE_DAY;   // 1 day in Unix epoch
        active = true;
    }


    // Getters

    function getUserSolvedTrivias(address userAddress) external view returns(uint8[] memory){
        return solvedTrivias[userAddress];
    }


    // Function to mint tokens ERC-20
    // is called when user has answered correctly a trivia
    function mint(address to, uint256 amount) private  {
        _mint(to, amount);
    }

    function giveFaucet(address _userAddress) external onlyOwner whenActive  {
        if (FaucetRegistry[_userAddress] == 0) {
            // new user
            FaucetRegistry[_userAddress] = block.timestamp;
            transferCrypto(payable(_userAddress));
        } else {
            // recurrent user, check time restriction (1 day has to have passed to request more crypto)
            if (FaucetRegistry[_userAddress] +  i_oneDay <= (block.timestamp )) {
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

// checkAnswer 
//      user send answers nad indexTrivia trivia to check if correct. 
//      if correct and hasn't been answered before, grant 10 tokes and register it's been answered
    function checkAnswer(uint8 indexTrivia,  string memory solution) external whenActive returns (bool) {
           if (keccak256(abi.encodePacked(solution)) != solutionsHash[indexTrivia]) {
                return false;
            }
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
}
