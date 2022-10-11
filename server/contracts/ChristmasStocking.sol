// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "./utils/Uint8a32.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract ChristmasStocking is RandomnessConsumer {

    using Uint8a32 for uint;
    using SafeMath for uint;

    address public immutable OWNER;
    bytes32 private immutable SALT;

    Randomness private randomness = Randomness(0x0000000000000000000000000000000000000809);

    uint64 private FULFILLMENT_GAS_LIMIT = 100000;
    uint private MIN_FEE = FULFILLMENT_GAS_LIMIT * 2 gwei;
    uint private DEPOSIT = 1 ether;

    uint public originAmount;
    uint public originMoney;
    uint public currentAmount;
    uint public currentMoney;

    uint public requestID = 2 ** 64 - 1;
    uint private result;
    bool public done;

    uint public participateCount;
    mapping(address => bool) public participateIn;

    modifier canParticipate(address _sender) {
        if (
            currentAmount == 0 ||
            currentMoney == 0 ||
            participateIn[_sender] ||
            !done
        ) revert CantParticipate();
        _;
    }

    event ParticipateEvent(address indexed participant, uint reward, uint randomWord);

    error NotEnoughFee(uint value, uint required);
    error DepositTooLow(uint value, uint required);
    error CantParticipate();

    constructor(address _owner, bytes32 _salt, uint _amount, uint _money) payable RandomnessConsumer() {
        OWNER = _owner;
        SALT = _salt;
        (originAmount, currentAmount) = (_amount, _amount);
        (originMoney, currentMoney) = (_money, _money);
    }

    function requestRandomWord() external payable {
        uint fee = msg.value;
        if (fee < MIN_FEE) revert NotEnoughFee(fee, MIN_FEE);

        uint balance = address(this).balance;
        uint deposit = balance - originMoney;
        uint required = randomness.requiredDeposit();
        if (deposit < required) revert DepositTooLow(balance, required);

        requestID = randomness.requestLocalVRFRandomWords(
            OWNER,
            fee,
            FULFILLMENT_GAS_LIMIT,
            SALT,
            uint8(originAmount - 1),
            2
        );
    }

    function fulfillRequest() external {
        randomness.fulfillRequest(requestID);
    }

    function increaseRequestFee() external payable {
        randomness.increaseRequestFee(requestID, msg.value);
    }

    function participate(address _sender) external canParticipate(_sender) {
        participateIn[_sender] = true;

        uint randomWord = result.get(originAmount - currentAmount);
        uint reward = currentAmount == 1 ?
            currentMoney :
            currentMoney.mul(randomWord).div(100);

        currentAmount -= 1;
        currentMoney -= reward;

        (bool ok,) = payable(_sender).call{value: reward}("");
        require(ok);

        emit ParticipateEvent(_sender, reward, randomWord);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        done = true;
        for (uint32 i = 0; i < randomWords.length; i++) {
            result = result.set(i, randomWords[i] % 100);
        }
    }

    function getRequestStatus() public view returns (uint) {
        return uint(randomness.getRequestStatus(requestID));
    }
}