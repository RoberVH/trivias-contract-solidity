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


contract TriviasContract is ERC20 {
    error NotOwner();
    error NoEnoughTimePassed();
    error NoEnoughBalanceInContract();
    error NoBalanceTowithdraw();
    error ContractInactive();
    error TriviaAlreadySolved();
    error AnsweredIncorrect();
    error InsufficientTokensInContract();


    event Transfer(address indexed recipient, uint256 amount);

    uint8 constant NUMBER_ANSWERS = 5; // number of asnwers for each trivia
    uint8 constant NUMBER_TRIVIAS = 6; // number of  trivias
    uint256 constant ONE_DAY = 86400;
    uint256 private constant TOKEN_UNIT = 1e18; // 10 ** 18; // for efficiency on tokens operations
    uint8 constant TOKENS_GRANT = 10; // Number of contracts tokens to grant on each correctlye trivia answered
    uint256 private constant INITIAL_SUPPLY = 500000 * TOKEN_UNIT; // five hundred thousand gives us fifty thousand rewards for answered trivias 🙂

    uint256 public immutable i_oneDay;
    address private owner;
    bool private active;
    uint256 private faucetGrant = 0.1 ether; // Ethereums to send from Faucet contrat

    mapping(address => uint256) private FaucetRegistry;

    bytes32[NUMBER_TRIVIAS] private solutionsHash;

    // keep track of which trivias has the address  solved
    mapping(address => uint8[]) private solvedTrivias;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Allow Deactivation of contract
    modifier whenActive() {
        if (!active) revert ContractInactive();
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
        solutionsHash[0] = 0xb3da42bc5c78803780ab5ede1dca1af79792697bb15ea77fb148f63304ec38a3;
        solutionsHash[1] = 0x17b389832821e5863cf5925dcb9d32e6fd66f782f28f4b79178fe7ce26279b2f;
        solutionsHash[2] = 0x520cf3b88dda50d5268f9e301368b94ba287dde0d608dfd19987cde0710a6855;
        solutionsHash[3] = 0xee1421cb94aeddf0678f494295468373d934c53bd3ccf5b2adcd17603b720c9b;
        solutionsHash[4] = 0x7edb8cbb43220aabf89e76e0527679bdf7d7e86df257082e57a02e83803e720f;
        solutionsHash[5] = 0x480eeff190b1da1d3fc451596c9f086abef656466ac7cf84b302442f16fe7216;
                             

        i_oneDay = ONE_DAY; // 1 day in Unix epoch
        _mint(address(this), INITIAL_SUPPLY);
        active = true;
    }

    // Getters

    function getUserSolvedTrivias(
        address userAddress
    ) external view returns (uint8[] memory) {
        return solvedTrivias[userAddress];
    }

    // Function to transfer Tokens ERC-20 to user account
    // is called when user has answered correctly a trivia
    function assignTokens(address to, uint8 amount) private {
        // if (balanceOf(address(this)) < TOKENS_GRANT * TOKEN_UNIT)
        //     revert InsufficientTokensInContract();
        _transfer(address(this), to, amount * TOKEN_UNIT);
    }

    function getDecimals() public view returns (uint8) {
        return decimals();
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function giveFaucet(address _userAddress) external onlyOwner whenActive {
        if (FaucetRegistry[_userAddress] == 0) {
            // new user
            FaucetRegistry[_userAddress] = block.timestamp;
            transferCrypto(payable(_userAddress));
        } else {
            // recurrent user, check time restriction (1 day has to have passed to request more crypto)
            if (FaucetRegistry[_userAddress] + i_oneDay <= (block.timestamp)) {
                // ok renew to current time the time restriction and transfer the crypto
                FaucetRegistry[_userAddress] = block.timestamp;
                transferCrypto(payable(_userAddress));
            } else {
                revert NoEnoughTimePassed();
            }
        }
    }

    function transferCrypto(address payable recipient) private whenActive {
        if (address(this).balance <= faucetGrant) {
            revert NoEnoughBalanceInContract();
        } else {
            recipient.transfer(faucetGrant);
            emit Transfer(recipient, faucetGrant);
        }
    }

    /**
     *  scoreAnswer
     * @param solution string
     * @param indexTrivia uint8 
     *       user send answers (solution) and indexTrivia trivia for contract to check if correct.
             if correct and hasn't been answered before, grant 10 tokes TTS and acruee this account user and trivia's been answered 
    **/
    function scoreAnswer(
        uint8 indexTrivia,
        string memory solution
    ) external whenActive  {
        if (
            keccak256(abi.encodePacked(solution)) != solutionsHash[indexTrivia]
        ) {
            revert AnsweredIncorrect();
        }
        uint8[] memory userSolvedTrivias = solvedTrivias[msg.sender];
        uint8 totalSolved = uint8(userSolvedTrivias.length);
        for (uint8 i = 0; i < totalSolved; i++) {
            if (userSolvedTrivias[i] == indexTrivia) {
                revert TriviaAlreadySolved();
            }
        }
        solvedTrivias[msg.sender].push(indexTrivia);
        assignTokens(msg.sender, TOKENS_GRANT); // grant 10 tokens for each correctly asnwered trivia
    }

    function getFaucetGrant() external view returns(uint256) {
        return faucetGrant;
    }

    function setFaucetGrant(uint256 _faucetGrant) external onlyOwner{
        faucetGrant = _faucetGrant;
    }

    // Make this contract able to receive ether
    receive() external payable {}

    // In case a transacction without data is receive, get the crypto
    fallback() external payable {}

    // to withdraw contract's balance in case owner deprecate it
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (!(balance > 0)) {
            revert NoBalanceTowithdraw();
        }

        (bool success, ) = owner.call{ value: balance }("");
        require(success, "Transfer failed");
    }

    // When/if contract is retired
    function deactivate() external onlyOwner {
        active = false;
    }
}
