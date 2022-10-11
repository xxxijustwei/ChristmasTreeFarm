// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "./utils/Uint8a32.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

uint64 constant FULFILLMENT_GAS_LIMIT = 100000;
uint constant MIN_FEE = FULFILLMENT_GAS_LIMIT * 2 gwei;
uint constant DEPOSIT = 1 ether;

contract ChristmasStocking is RandomnessConsumer {

    using Uint8a32 for uint;
    using SafeMath for uint;

    address public owner;
    bytes32 private salt;

    Randomness private randomness = Randomness(0x0000000000000000000000000000000000000809);

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
        owner = _owner;
        salt = _salt;
        (originAmount, currentAmount) = (_amount, _amount);
        (originMoney, currentMoney) = (_money, _money);

        requestID = randomness.requestLocalVRFRandomWords(
            owner,
            MIN_FEE,
            FULFILLMENT_GAS_LIMIT,
            salt,
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

        uint random = result.get(originAmount - currentAmount);
        uint reward = currentAmount == 1 ?
            currentMoney :
            (currentMoney.mul(10).div(currentAmount.mul(5))).mul(random).div(100);

        currentAmount -= 1;
        currentMoney -= reward;

        (bool ok,) = payable(_sender).call{value: reward}("");
        require(ok);

        emit ParticipateEvent(_sender, reward, random);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        done = true;
        for (uint32 i = 0; i < randomWords.length; i++) {
            uint random = randomWords[i];
            uint scope = random % 16;
            uint value = random % 2 == 0 ? 50 + scope : 50 - scope;

            result = result.set(i, value);
        }
    }

    function getRequestStatus() public view returns (uint) {
        return uint(randomness.getRequestStatus(requestID));
    }
}