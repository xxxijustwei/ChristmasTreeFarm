// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IChristmasFarm.sol";
import "./access/Roles.sol";
import { Utils } from "./util/Utils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// deploy network: moonbase alpha
// deploy address: 0x7970977BbA896915d705806b0891B148d236Bbfe
contract ChristmasTree is IChristmasFarm, Roles {
    using SafeMath for uint;

    mapping(string => Socks) private presentMap;
    mapping(string => mapping(address => bool)) private record;

    mapping(string => bool) private contains;
    mapping(string => bool) private empty;

    mapping(address => string[]) private sent;
    mapping(address => string[]) private claimed;

    mapping(address => uint) private accumSend;
    mapping(address => uint) private accumClaim;

    modifier containsPresent(string memory _key) {
        if (!contains[_key]) revert PresentNotExistsError(_key);
        _;
    }

    modifier presentNotEmpty(string memory _key) {
        if (empty[_key]) revert PresentEmptyError(_key);
        _;
    }

    modifier presentNotClaimed(address sender, string memory _key) {
        if (record[_key][sender]) revert PresentAlreadyClaimedError(_key);
        _;
    }

    modifier isValidValue(string calldata _key, uint _value, uint _amount) {
        if (_value == 0) revert PresentInvalidValueError(_key, _value);
        uint per = _value / _amount;
        if (per * _amount != _value) revert PresentInvalidValueError(_key, _value);
        _;
    }

    constructor() Roles(_msgSender()) {}

    receive() external payable {}

    function createPresent(string calldata _key, uint _amount, uint _cBalance, bool _average)
        external
        payable
        isValidValue(_key, msg.value, _amount)
    {
        if (contains[_key]) revert PresentAlreadyExistsError(_key);

        address sender = _msgSender();
        uint balance = msg.value;

        presentMap[_key] = Socks({
            creator: sender,
            initAmount: _amount,
            initBalance: balance,
            currentAmount: _amount,
            currentBalance: balance,
            conditionBalance: _cBalance,
            isAverage: _average
        });
        sent[sender].push(_key);
        contains[_key] = true;

        uint accum = accumSend[sender];
        accumSend[sender] = accum + balance;

        emit CreatePresentEvent(sender, _key);
    }
    
    function claimPresent(string memory _key)
        external
        containsPresent(_key)
        presentNotEmpty(_key)
        presentNotClaimed(_msgSender(), _key)
        returns (uint)
    {
        Socks storage present = presentMap[_key];
        address sender = _msgSender();
        if (present.conditionBalance > sender.balance) revert PresentNotMeetConditionError(_key);

        record[_key][sender] = true;
        claimed[sender].push(_key);

        uint amount = present.currentAmount;
        uint balance = present.currentBalance;
        uint value = present.isAverage
            ? (balance.div(amount))
            :
                (
                    amount == 1
                    ? balance
                    : Utils.random(balance.mul(10).div(amount.mul(10).div(2)))
                );

        present.currentAmount -= 1;
        present.currentBalance -= value;

        if (present.currentAmount == 0) {
            empty[_key] = true;
        }

        uint accum = accumClaim[sender];
        accumClaim[sender] = accum + value;

        payable(sender).transfer(value);

        emit ClaimedPresentEvent(sender, _key, value);
        return value;
    }

    function getSentPresents()
        external
        view
        returns (string[] memory keys)
    {
        keys = sent[_msgSender()];
    }

    function getPresentInfo(string calldata _key)
        external
        view
        containsPresent(_key)
    returns (
        address creator,
        uint initAmount,
        uint initBalance,
        uint currentAmount,
        uint currentBalance,
        uint cBalance,
        bool average
    )
    {
        Socks memory present = presentMap[_key];
        creator = present.creator;
        initAmount = present.initAmount;
        initBalance = present.initBalance;
        currentAmount = present.currentAmount;
        currentBalance = present.currentBalance;
        cBalance = present.conditionBalance;
        average = present.isAverage;
    }

    function getAccumSend() external view returns (uint) {
        return accumSend[_msgSender()];
    }

    function getAccumClaim() external view returns (uint) {
        return accumClaim[_msgSender()];
    }

    function canClaim(string calldata _key) external view returns (bool) {
        return (contains[_key] && !empty[_key]);
    }
}