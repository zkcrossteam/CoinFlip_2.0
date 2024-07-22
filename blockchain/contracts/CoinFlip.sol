// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Errors.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./zkcvrfCallbackIface.sol";
import "./zkcvrfIface.sol";

contract CoinFlip is zkcvrfCallbackIface, ReentrancyGuard, Ownable {
    /* Storage:
     ***********/

    zkcvrfIface _vrf;

    modifier onlyVrfContract() {
        require(msg.sender == address(_vrf), "Unauthorized access");
        _;
    }

    uint256 public constant MIN_BET = 0.001 ether;
    uint256 private contractBalance;

    struct PlayerByAddress {
        uint256 balance;
        uint256 betAmount;
        uint256 betChoice;
        address playerAddress;
        bool betOngoing;
    }

    struct Temp {
        uint256 id;
        uint256 result;
        address playerAddress;
    }

    /// @notice Get player struct by address
    mapping(address => PlayerByAddress) public playersByAddress;

    /// @notice Get pending bet struct by requestId
    mapping(uint256 => Temp) public temps;

    /* Events:
     *********/

    event DepositToContract(address indexed user, uint256 indexed depositAmount, uint256 newBalance);
    event Withdrawal(address player, uint256 amount);
    event NewIdRequest(address indexed player, uint256 requestId);
    event GeneratedRandomNumber(uint256 requestId, uint256 randomNumber);
    event BetResult(address indexed player, bool victory, uint256 amount);
    event ContractBalanceWithdrawn(address indexed owner, uint256 amount);

    /* Constructor:
     **************/

    constructor(address _zkcvrf) Ownable(msg.sender) payable {
        _vrf = zkcvrfIface(_zkcvrf);
        if (msg.value < 0.1 ether) revert CoinFlip__ContractNeedsETH();
        contractBalance += msg.value;
    }

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows a player to bet on heads or tails
     * @param _betChoice 0 for heads, 1 for tails
     */
    function bet(uint256 _seed, uint256 _grouphash, uint256 _betChoice) public payable nonReentrant {
        if (msg.value < MIN_BET) revert CoinFlip__InsuffisantAmount();
        if (msg.value > getContractBalance() / 2) revert CoinFlip__AmountTooBig();
        if (_betChoice != 0 && _betChoice != 1) revert CoinFlip__InvalidBetChoice();

        address player = msg.sender;
        PlayerByAddress memory _player = playersByAddress[player];

        if (_player.betOngoing) revert CoinFlip__BetAlreadyOngoing();

        _player.playerAddress = player;
        _player.betChoice = _betChoice;
        _player.betOngoing = true;
        _player.betAmount = msg.value;

        playersByAddress[player] = _player;
        contractBalance += _player.betAmount;

        uint256 requestId = _seed;
	requestRandomWords(_seed, _grouphash);
        temps[requestId].playerAddress = player;
        temps[requestId].id = requestId;

        emit NewIdRequest(player, requestId);
    }

    /**
     * @notice Allows players to withdraw their balance
     */
    function withdrawPlayerBalance() public nonReentrant {
        address player = msg.sender;
        if (playersByAddress[player].betOngoing) revert CoinFlip__BetOngoing();
        if (playersByAddress[player].balance == 0) revert CoinFlip__NoFundsToWithdraw();

        uint256 amount = playersByAddress[player].balance;
        delete (playersByAddress[player]);

        (bool success, ) = payable(player).call{ value: amount }("");
        if (!success) revert CoinFlip__WithdrawFailed();

        emit Withdrawal(player, amount);
    }

    /**
     * @notice Deposit ETH to the contract
     */
    function deposit() public payable {
        if (msg.value == 0) revert CoinFlip__InsuffisantAmount();
        contractBalance += msg.value;
        emit DepositToContract(msg.sender, msg.value, contractBalance);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPlayerBalance() public view returns (uint256) {
        return playersByAddress[msg.sender].balance;
    }

    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    /*//////////////////////////////////////////////////////////////
                        PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint256 seed, uint256 group_hash) private {
	    _vrf.create_random(seed, address(this), group_hash);
    }

    //function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
    function handle_random(uint256 _requestId, uint256 _randomWords) public onlyVrfContract {
        uint256 randomResult = _randomWords % 2;
        temps[_requestId].result = randomResult;

        checkResult(randomResult, _requestId);
        emit GeneratedRandomNumber(_requestId, randomResult);
    }

    /**
     * @notice Check if the player won the bet and update the player's balance accordingly
     * @param _randomResult The random number generated by Chainlink VRF
     * @param _requestId The requestId of the VRF call
     * @return win True if the player won the bet, false otherwise
     */
    function checkResult(uint256 _randomResult, uint256 _requestId) private returns (bool) {
        address player = temps[_requestId].playerAddress;
        bool win = false;
        uint256 amountWon = 0;

        PlayerByAddress memory _player = playersByAddress[player];

        if (_player.betChoice == _randomResult) {
            win = true;
            amountWon = _player.betAmount * 2;
            _player.balance += amountWon;
            contractBalance -= amountWon;
        }

        _player.betAmount = 0;
        _player.betOngoing = false;
        playersByAddress[player] = _player;

        emit BetResult(player, win, amountWon);

        delete (temps[_requestId]);
        return win;
    }

    /*//////////////////////////////////////////////////////////////
                        RESTRCITED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdrawContractBalance() public onlyOwner {
        if (contractBalance == 0) revert CoinFlip__NoFundsToWithdraw();

        uint256 toTransfer = address(this).balance;
        contractBalance = 0;
        (bool success, ) = payable(owner()).call{ value: toTransfer }("");
        if (!success) revert CoinFlip__WithdrawFailed();

        emit ContractBalanceWithdrawn(owner(), toTransfer);
    }
}
