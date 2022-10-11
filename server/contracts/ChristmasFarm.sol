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
    error NotEnoughMoney(uint money, uint deposit);

    function create(uint _key, uint _amount) external payable {
        require(_amount <= 32, "Amount cannot be greater than 32");

        if (_getUintLength(_key) != KEY_LENGTH) revert InvalidKeyLength(_key, KEY_LENGTH);
        if (contains[_key]) revert PresentAlreadyExists(_key);

        address sender = msg.sender;
        uint value = msg.value;

        uint cost = DEPOSIT + MIN_FEE;
        if (value <= cost) revert NotEnoughMoney(value, cost);

        uint money = value - cost;
        bytes32 salt = _getSalt(_key);

        ChristmasStocking stocking = new ChristmasStocking{value: value, salt: salt}(sender, salt, _amount, money);
        contains[_key] = true;
        presents[_key] = stocking;
        owners[_key] = sender;

        emit ChristmasCreateEvent(_key, address(stocking));
    }

    function getAddress(uint _key) external exists(_key) view returns (address) {
        return address(presents[_key]);
    }

    function _getUintLength(uint _key) internal pure returns (uint) {
        return bytes(Strings.toString(_key)).length;
    }

    function _getSalt(uint _key) internal pure returns (bytes32) {
        return keccak256(abi.encodeWithSignature("taylor", _key, 1989));
    }

}