// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ChristmasStocking is RandomnessConsumer {

    using SafeMath for uint;

    address public owner;

    Randomness private randomness = Randomness(0x0000000000000000000000000000000000000809);

    uint64 private FULFILLMENT_GAS_LIMIT = 100000;
    uint private MIN_FEE = 300000 gwei;
    uint private DEPOSIT = 1 ether;
    bytes32 private SALT_PREFIX;
    uint private globalRequestCount;

    uint public originCount;
    uint public originAmount;
    uint public currentCount;
    uint public currentAmount;

    uint public requestID = 2 ** 64 - 1;
    uint[] private results;
    bool public done;

    uint public participateCount;
    mapping(address => bool) public participateIn;

    modifier canParticipate(address _sender) {
        if (
            currentCount == 0 ||
            currentAmount == 0 ||
            participateIn[_sender] ||
            !done
        ) revert CantParticipate();
        _;
    }

    event ParticipateEvent(address indexed participant, uint reward, uint randomWord);

    error NotEnoughFee(uint value, uint required);
    error DepositTooLow(uint value, uint required);
    error CantParticipate();

    constructor(address _owner, bytes32 _salt, uint _count, uint _amount) payable RandomnessConsumer() {
        owner = _owner;
        SALT_PREFIX = _salt;
        (originCount, currentCount) = (_count, _count);
        (originAmount, currentAmount) = (_amount, _amount);
        globalRequestCount = 0;

        _requestRandomenss();
    }

    function _requestRandomenss() internal {
        uint balance = address(this).balance;

        uint fee = balance - DEPOSIT - originAmount;
        if (fee < MIN_FEE) revert NotEnoughFee(fee, MIN_FEE);

        uint deposit = balance - fee - originAmount;
        uint required = randomness.requiredDeposit();
        if (deposit < required) revert DepositTooLow(balance, required);

        requestID = randomness.requestLocalVRFRandomWords(
            owner,
            fee,
            FULFILLMENT_GAS_LIMIT,
            SALT_PREFIX,
            uint8(originCount - 1),
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

        uint word = results[originCount - currentCount];
        uint reward = currentCount == 1 ?
            currentAmount :
            word % (currentAmount.mul(10).div(currentCount.mul(10).div(2)));

        currentCount -= 1;
        currentAmount -= reward;

        (bool ok,) = payable(_sender).call{value: reward}("");
        require(ok);

        emit ParticipateEvent(_sender, reward, word);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) override internal {
        results = randomWords;
        done = true;
    }

    function getRequestStatus() public view returns (uint) {
        return uint(randomness.getRequestStatus(requestID));
    }
}