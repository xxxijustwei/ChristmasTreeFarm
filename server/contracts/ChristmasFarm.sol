// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./ChristmasStocking.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChristmasFarm {

    uint public constant KEY_LENGTH = 6;

    mapping(uint => bool) contains;
    mapping(uint => ChristmasStocking) public presents;
    mapping(uint => address) private owners;

    modifier exists(uint _key) {
        if (!contains[_key]) revert PresentNotExists(_key);
        _;
    }

    event ChristmasCreateEvent(uint indexed key, address indexed addr);
    event ChristmasParticipateEvent(uint indexed key, bool success);

    error InvalidKeyLength(uint key, uint requireLen);
    error PresentAlreadyExists(uint key);
    error PresentNotExists(uint key);
    error NotEnoughAmount(uint money, uint deposit);
    error InvalidAmount(uint count, uint amount);

    function create(uint _key, uint _count) external payable {
        if (getUintLength(_key) != KEY_LENGTH) revert InvalidKeyLength(_key, KEY_LENGTH);
        if (contains[_key]) revert PresentAlreadyExists(_key);

        address sender = msg.sender;
        uint value = msg.value;

        uint deposit = _count * 10 ** 18;
        if (value <= deposit) revert NotEnoughAmount(value, deposit);
        uint amount = value - deposit;
        uint per = amount / _count;
        if (per * _count != amount) revert InvalidAmount(_count, amount);

        ChristmasStocking stocking = (new ChristmasStocking){value: value}(sender, bytes32(_key), _count, amount);
        contains[_key] = true;
        presents[_key] = stocking;
        owners[_key] = sender;

        emit ChristmasCreateEvent(_key, address(stocking));
    }

    function participate(uint _key) external payable exists(_key) {
        presents[_key].participate{value: msg.value}(msg.sender);
    }

    function claim(uint _key) external exists(_key) {
        presents[_key].claim(msg.sender);
    }

    function get(uint _key) external exists(_key) view returns (address) {
        return address(presents[_key]);
    }

    function getUintLength(uint _value) internal pure returns (uint) {
        return bytes(Strings.toString(_value)).length;
    }
}