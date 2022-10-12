// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "./utils/Uint8a32.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

uint64 constant FULFILLMENT_GAS_LIMIT = 100000;
uint constant MIN_FEE = FULFILLMENT_GAS_LIMIT * 2 gwei;
uint constant DEPOSIT = 1 ether;

contract ChristmasStocking is RandomnessConsumer {

    using Uint8a32 for uint;
    using SafeMath for uint;

    address public factory;
    address public owner;
    bytes32 private salt;

    Randomness private randomness = Randomness(0x0000000000000000000000000000000000000809);

    uint private key;
    uint public originAmount;
    uint public originMoney;
    uint public currentAmount;
    uint public currentMoney;

    uint public requestID = 2 ** 64 - 1;
    uint private result;
    bool public done;

    uint public participateCount;
    mapping(address => bool) public participateIn;

    modifier canParticipate() {
        if (
            currentAmount == 0 ||
            currentMoney == 0 ||
            participateIn[msg.sender] ||
            !done
        ) revert CantParticipate();
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied");
        _;
    }

    event ParticipateEvent(address indexed participant, uint reward, uint randomWord);

    error NotEnoughFee(uint value, uint required);
    error DepositTooLow(uint value, uint required);
    error CantParticipate();

    constructor() payable RandomnessConsumer() {
        factory = msg.sender;
    }

    function initialize(address _owner, uint _key, bytes32 _salt, uint _amount, uint _money) external {
        owner = _owner;
        salt = _salt;
        key = _key;
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

    function fulfillRequest() external onlyOwner {
        require(getRequestStatus() == 2, "fulfillRequest failure");
        randomness.fulfillRequest(requestID);
    }

    function increaseRequestFee() external payable onlyOwner {
        randomness.increaseRequestFee(requestID, msg.value);
    }

    function participate() external canParticipate() {
        address sender = msg.sender;
        participateIn[sender] = true;

        uint random = result.get(originAmount - currentAmount);
        uint reward = currentAmount == 1 ?
            currentMoney :
            (currentMoney.mul(10).div(currentAmount.mul(5))).mul(random).div(100);

        currentAmount -= 1;
        currentMoney -= reward;

        (bool ok,) = payable(sender).call{value: reward}("");
        require(ok, "Participate in failure");

        if (currentAmount == 0) {
            (bool a,) = factory.call(abi.encodeWithSignature("remove(uint256)", key));
            (bool b,) = payable(owner).call{value: address(this).balance}("");
            require(a && b, "Participate in failure!");
        }

        emit ParticipateEvent(sender, reward, random);
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