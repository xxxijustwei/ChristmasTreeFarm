// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IChristmasFarm.sol";
import "../access/Roles.sol";
import { Utils } from "../util/Utils.sol";


// deploy network: moonbase alpha
// deploy address: 0x7970977BbA896915d705806b0891B148d236Bbfe
contract ChristmasTree is IChristmasFarm, Roles {

    mapping(string => Socks) private presents;
    mapping(string => mapping(address => bool)) private record;

    mapping(string => bool) private contains;
    mapping(string => bool) private empty;

    mapping(address => string[]) private sent;
    mapping(address => string[]) private claimed;
    mapping(address => uint) private accumulative;

    modifier containsPresent(string calldata _key) {
        if (!contains[_key]) revert ChristmasPresentNotExistsError(_key);
        _;
    }

    constructor() Roles(_msgSender()) {}

    receive() external payable {}

    function createPresent(string calldata _key, uint _amount, uint _cBalance, bool _average)
    external
    payable
    {
        require(msg.value != 0, "The balance in the present cannot be zero!");
        if (contains[_key]) revert ChristmasPresentAlreadyExistsError(_key);

        address sender = _msgSender();
        uint balance = msg.value;

        presents[_key] = Socks({
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

        emit ChristmasCreatePresentEvent(sender, _key);
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
        Socks memory present = presents[_key];
        creator = present.creator;
        initAmount = present.initAmount;
        initBalance = present.initBalance;
        currentAmount = present.currentAmount;
        currentBalance = present.currentBalance;
        cBalance = present.conditionBalance;
        average = present.isAverage;
    }

    function claimPresent(string calldata _key)
    external
    payable
    returns (uint)
    {
        if (!contains[_key]) revert ChristmasPresentNotExistsError(_key);
        if (empty[_key]) revert ChristmasPresentEmptyError(_key);

        Socks storage present = presents[_key];
        address sender = _msgSender();
        if (record[_key][sender]) revert ChristmasPresentClaimedError(_key);
        if (present.conditionBalance > sender.balance) revert ChristmasPresentConditionLimitError(_key);

        claimed[sender].push();

        record[_key][sender] = true;

        if (present.isAverage) {
            uint value = present.currentBalance / present.currentAmount;

            present.currentAmount -= 1;
            present.currentBalance -= value;

            if (present.currentAmount == 0) {
                empty[_key] = true;
            }

            claimed[sender].push(_key);
            uint history = accumulative[sender];
            accumulative[sender] = history + value;

            payable(_msgSender()).transfer(value);
            emit ChristmasClaimedPresentEvent(sender, _key, value);
            return value;
        }

        if (present.currentAmount == 1) {
            uint value = present.currentBalance;
            present.currentAmount = 0;
            present.currentBalance = 0;

            if (present.currentAmount == 0) {
                empty[_key] = true;
            }

            claimed[sender].push(_key);
            uint history = accumulative[sender];
            accumulative[sender] = history + value;

            payable(_msgSender()).transfer(value);
            emit ChristmasClaimedPresentEvent(sender, _key, value);
            return value;
        } else {
            uint min = 1;
            uint max = present.currentBalance / present.currentAmount * 2;
            uint value = (Utils.random(100) * max) / 100;
            value = value < min ? min : value;

            present.currentAmount -= 1;
            present.currentBalance -= value;

            if (present.currentAmount == 0) {
                empty[_key] = true;
            }

            claimed[sender].push(_key);
            uint history = accumulative[sender];
            accumulative[sender] = history + value;

            payable(_msgSender()).transfer(value);
            emit ChristmasClaimedPresentEvent(sender, _key, value);
            return value;
        }
    }
}