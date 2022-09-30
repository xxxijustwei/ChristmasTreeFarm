// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IChristmasFarm.sol";
import "./access/Roles.sol";
import "./randomness/Randomness.sol";
import "./randomness/RandomnessConsumer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// deploy network: moonbase alpha
contract ChristmasTree is IChristmasFarm, Roles, RandomnessConsumer {
    using SafeMath for uint;

    Randomness public randomness = Randomness(0x0000000000000000000000000000000000000809);

    mapping(string => Socks) private presentMap;
    mapping(string => mapping(address => bool)) private record;

    mapping(string => bool) private contains;
    mapping(string => bool) private empty;

    mapping(address => string[]) private sent;
    mapping(address => mapping(string => bool)) private participateIn;
    mapping(address => mapping(string => bool)) private claimed;

    mapping(address => uint) private accumSend;
    mapping(address => uint) private accumClaim;

    uint64 public FULFILLMENT_GAS_LIMIT = 100000;
    uint256 public MIN_FEE = FULFILLMENT_GAS_LIMIT * 1 gwei;
    uint256 public PARTICIPATION_FEE = 100000 gwei;
    bytes32 public SALT_PREFIX = "christmas_tree_1989";
    uint256 public globalRequestCount;

    mapping(address => mapping(string => uint)) userRequireID;

    Randomness.RandomnessSource source;

    modifier containsPresent(string calldata _key) {
        if (!contains[_key]) revert PresentNotExists(_key);
        _;
    }

    modifier presentNotEmpty(string calldata _key) {
        if (empty[_key]) revert PresentEmpty(_key);
        _;
    }

    modifier presentNotClaimed(string calldata _key) {
        if (claimed[_msgSender()][_key]) revert PresentAlreadyClaimed(_key);
        _;
    }

    modifier presentNotParticipate(string calldata _key) {
        if (participateIn[_msgSender()][_key]) revert PresentAlreadyParticipate(_key);
        _;
    }

    constructor(Randomness.RandomnessSource _source)
        payable
        Roles(_msgSender())
        RandomnessConsumer()
    {
        uint value = msg.value;
        uint required = randomness.requiredDeposit();
        if (value < required) revert DepositTooLow(value, required);

        source = _source;
        globalRequestCount = 0;
    }

    receive() external payable {}

    function create(string calldata _key, uint _amount, bool _average)
        override
        external
        payable
    {
        address sender = _msgSender();
        uint balance = msg.value;

        if (balance == 0) revert PresentInvalidValue(_key, balance);

        uint per = balance / _amount;
        if (per * _amount != balance) revert PresentInvalidValue(_key, balance);

        if (contains[_key]) revert PresentAlreadyExists(_key);

        presentMap[_key] = Socks({
        creator: sender,
        initAmount: _amount,
        initBalance: balance,
        currentAmount: _amount,
        currentBalance: balance,
        isAverage: _average
        });

        sent[sender].push(_key);
        contains[_key] = true;
        accumSend[sender] += balance;

        emit CreatePresentEvent(sender, _key);
    }

    function participate(string calldata _key)
        override
        external
        payable
        containsPresent(_key)
        presentNotParticipate(_key)
        presentNotEmpty(_key)
    {
        uint fee = msg.value;
        if (fee < MIN_FEE) revert NotEnoughFee(fee, MIN_FEE);
        uint balance = address(this).balance;
        uint required = randomness.requiredDeposit();
        if (balance < required) revert DepositTooLow(balance, required);

        address sender = _msgSender();
        uint requireID = userRequireID[sender][_key];

        participateIn[sender][_key] = true;

        if (source == Randomness.RandomnessSource.LocalVRF) {
            requireID = randomness.requestLocalVRFRandomWords(
                sender,
                fee,
                FULFILLMENT_GAS_LIMIT,
                SALT_PREFIX ^ bytes32(globalRequestCount++),
                1,
                2
            );
        } else {
            requireID = randomness.requestRelayBabeEpochRandomWords(
                sender,
                fee,
                FULFILLMENT_GAS_LIMIT,
                SALT_PREFIX ^ bytes32(globalRequestCount++),
                1
            );
        }
    }

    function claim(string calldata _key)
        override
        external
        containsPresent(_key)
        presentNotEmpty(_key)
        presentNotClaimed(_key)
        returns (uint)
    {
        Socks storage present = presentMap[_key];
        address sender = _msgSender();

        record[_key][sender] = true;
        claimed[sender][_key] = true;

        uint amount = present.currentAmount;
        uint balance = present.currentBalance;
        uint value = present.isAverage
        ? (balance.div(amount))
        :
        (
        amount == 1
        ? balance
        : _random(balance.mul(10).div(amount.mul(10).div(2)))
        );

        present.currentAmount -= 1;
        present.currentBalance -= value;

        if (present.currentAmount == 0) {
            empty[_key] = true;
        }

        accumClaim[sender] += value;

        (bool ok, ) = payable(sender).call{value: value}("");
        require(ok);

        emit ClaimedPresentEvent(sender, _key, value);
        return value;
    }

    function getSentPresents()
        override
        external
        view
        returns (string[] memory keys)
    {
        keys = sent[_msgSender()];
    }

    function getPresentInfo(string calldata _key)
        override
        external
        view
        containsPresent(_key)
        returns (
            address creator,
            uint initAmount,
            uint initBalance,
            uint currentAmount,
            uint currentBalance,
            bool average
        )
    {
        Socks storage present = presentMap[_key];
        creator = present.creator;
        initAmount = present.initAmount;
        initBalance = present.initBalance;
        currentAmount = present.currentAmount;
        currentBalance = present.currentBalance;
        average = present.isAverage;
    }

    function getAccumSend() override external view returns (uint) {
        return accumSend[_msgSender()];
    }

    function getAccumClaim() override external view returns (uint) {
        return accumClaim[_msgSender()];
    }

    function canClaim(string calldata _key) override external view returns (bool) {
        return (contains[_key] && !empty[_key]);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        override
        internal
    {
        // TODO
    }

    // unsafe
    function _random(uint number) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

}