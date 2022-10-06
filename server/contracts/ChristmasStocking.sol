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
    uint256 public MIN_FEE = FULFILLMENT_GAS_LIMIT * 1 gwei;
    bytes32 private SALT_PREFIX;
    uint256 private globalRequestCount;

    uint public initAmount;
    uint public initMoney;
    uint public currentAmount;
    uint public currentMoney;

    uint public participateCount;
    mapping(address => bool) private participateIn;

    mapping(address => bool) private claimed;

    mapping(address => uint) private userToRequest;
    mapping(uint => address) private requestToUser;

    modifier canParticipate() {
        require(currentMoney != 0 && !participateIn[msg.sender] && participateCount != initAmount);
        _;
    }

    modifier canClaim() {
        require(
            currentMoney != 0 &&
            participateIn[msg.sender] &&
            randomness.getRequestStatus(userToRequest[msg.sender]) == Randomness.RequestStatus.Ready
        );
        _;
    }

    constructor(bytes32 _salt, uint _amount, uint _money) payable RandomnessConsumer() {
        owner = msg.sender;
        (initAmount, currentAmount) = (_amount, _amount);
        (initMoney, currentMoney) = (_money, _money);
        SALT_PREFIX = _salt;
        globalRequestCount = 0;
    }

    function participate() external payable canParticipate {
        uint fee = msg.value;
        require(fee >= MIN_FEE);
        require(address(this).balance >= randomness.requiredDeposit());

        address sender = msg.sender;
        participateIn[sender] = true;
        participateCount++;

        uint id = randomness.requestLocalVRFRandomWords(
            owner,
            fee,
            FULFILLMENT_GAS_LIMIT,
            SALT_PREFIX ^ bytes32(globalRequestCount++),
            1,
            2
        );

        userToRequest[sender] = id;
        requestToUser[id] = sender;
    }

    function claim() external canClaim {
        randomness.fulfillRequest(userToRequest[msg.sender]);
    }

    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords) override internal {
        address user = requestToUser[requestID];
        allocate(user, randomWords[0]);
    }

    function allocate(address user, uint randomWord) internal {
        claimed[user] = true;

        uint reward = currentAmount == 1 ?
        currentMoney :
        randomWord % (currentMoney.mul(10).div(currentAmount.mul(10).div(2)));

        currentAmount--;
        currentMoney -= reward;

        (bool ok, ) = payable(user).call{value: reward}("");
        require(ok);
    }
}