// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "./utils/Uint8a32.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

uint64 constant FULFILLMENT_GAS_LIMIT = 100000;
uint constant MIN_FEE = FULFILLMENT_GAS_LIMIT * 2 gwei;
uint constant DEPOSIT = 1 ether;
uint8 constant MAX_AMOUNT = 32;
uint8 constant MAX_KEY_LENGTH = 8;

contract ChristmasStocking is RandomnessConsumer {

    using Uint8a32 for uint;
    using SafeMath for uint;

    uint private requestCounter;
    bytes32 private constant SALT = "taylor swift";
    Randomness private randomness = Randomness(0x0000000000000000000000000000000000000809);

    struct Stocking {
        uint amount;
        uint money;
        uint remainAmount;
        uint remainMoney;

        uint randomWord;

        mapping(address => bool) participateIn;
    }

    mapping(bytes32 => bool) private contains;
    mapping(bytes32 => bool) private finished;
    mapping(bytes32 => address) private owners;
    mapping(bytes32 => Stocking) private presents;

    mapping(uint => bytes32) requestToIdent;
    mapping(bytes32 => uint) identToRequest;

    event PresentsCreateEvent(bytes32 indexed ident, uint indexed key, uint indexed num);
    event PresentsParticipateEvent(bytes32 indexed ident, uint reward);

    error AmountBeyondError(uint amount, uint limited);
    error KeyLengthBeyondError(uint key, uint inputLen, uint requireLen);
    error MoneyNotEnoughError(uint inputMoney, uint actualMoney);
    error InvalidPresentsError();
    error PresentsWaitingError();

    modifier onlyOwner(bytes32 _ident) {
        require(owners[_ident] == msg.sender, "Not permission");
        _;
    }

    modifier isContain(bytes32 _ident) {
        if (!contains[_ident]) revert InvalidPresentsError();
        _;
    }

    modifier isValid(bytes32 _ident) {
        if (!finished[_ident]) revert PresentsWaitingError();
        _;
    }

    constructor() RandomnessConsumer() {
        requestCounter = 0;
    }

    function create(uint _key, uint _amount, uint _money) external payable {
        if (_amount > MAX_AMOUNT) revert AmountBeyondError(_amount, MAX_AMOUNT);

        uint len = _getKeyLength(_key);
        if (len > MAX_KEY_LENGTH) revert KeyLengthBeyondError(_key, len, MAX_KEY_LENGTH);

        address sender = msg.sender;
        uint value = msg.value;
        uint money = value.sub(DEPOSIT).sub(MIN_FEE);
        if (money != _money) revert MoneyNotEnoughError(_money, money);

        requestCounter++;
        bytes32 ident = _getIdentifier(_key);

        contains[ident] = true;
        owners[ident] = sender;

        Stocking storage gift = presents[ident];
        (gift.amount, gift.remainAmount) = (_amount, _amount);
        (gift.money, gift.remainMoney) = (_money, _money);

        uint requestID = randomness.requestLocalVRFRandomWords(
            address(this),
            MIN_FEE,
            FULFILLMENT_GAS_LIMIT,
            SALT ^ bytes32(requestCounter),
            uint8(_amount - 1),
            2
        );
        requestToIdent[requestID] = ident;
        identToRequest[ident] = requestID;

        emit PresentsCreateEvent(ident, _key, requestCounter);
    }

    function participate(bytes32 _ident) external isContain(_ident) isValid(_ident) {
        address sender = msg.sender;
        Stocking storage gift = presents[_ident];
        require(gift.remainAmount != 0, "Gift is empty");
        require(!gift.participateIn[sender], "You have already participate");

        uint random = gift.randomWord.get(gift.amount - gift.remainAmount);

        gift.participateIn[sender] = true;
        gift.remainAmount--;

        uint reward = gift.remainAmount == 0 ?
            gift.remainMoney :
            (gift.remainMoney.mul(10).div(gift.remainAmount.add(1).mul(5))).mul(random).div(100);
        gift.remainMoney -= reward;

        payable(sender).transfer(reward);

        emit PresentsParticipateEvent(_ident, reward);
    }

    function drawback(bytes32 _ident) external onlyOwner(_ident) isContain(_ident) {
        Stocking storage gift = presents[_ident];
        require(gift.remainAmount == 0, "There are still gifts left");
        require(address(this).balance >= 1, "Drawback failure");

        uint requestID = identToRequest[_ident];

        delete contains[_ident];
        delete finished[_ident];
        delete owners[_ident];
        delete presents[_ident];
        delete requestToIdent[requestID];
        delete identToRequest[_ident];

        payable(msg.sender).transfer(1 ether);
    }

    function fulfillRequest(bytes32 _ident) external onlyOwner(_ident) isContain(_ident) {
        uint requestID = identToRequest[_ident];
        require(uint(randomness.getRequestStatus(requestID)) == 2, "waiting for parachain");

        randomness.fulfillRequest(requestID);
    }

    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords) internal override {
        bytes32 ident = requestToIdent[requestID];
        uint result;
        uint len = randomWords.length;
        for (uint i; i < len; i++) {
            uint random = randomWords[i];
            uint scope = random % 16;
            uint value = random % 2 == 0 ? 50 + scope : 50 - scope;

            result = result.set(i, value);
        }

        Stocking storage gift = presents[ident];
        gift.randomWord = result;

        finished[ident] = true;
    }

    function getRequestStatus(bytes32 _ident) external view returns (uint) {
        uint requestID = identToRequest[_ident];
        return uint(randomness.getRequestStatus(requestID));
    }

    function getCounter() external view returns (uint) {
        return requestCounter;
    }

    function _getIdentifier(uint _key) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(_key, SALT, requestCounter));
    }

    function _getKeyLength(uint _key) internal pure returns (uint) {
        return bytes(Strings.toString(_key)).length;
    }
}