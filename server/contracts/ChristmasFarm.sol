// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./ChristmasStocking.sol";

contract ChristmasFarm {

    mapping(string => bool) contains;
    mapping(string => ChristmasStocking) private presents;
    mapping(string => address) private owners;

    modifier exists(string calldata _key) {
        require(contains[_key]);
        _;
    }

    function create(string calldata _key, uint _amount, uint _money) external payable {
        uint value = msg.value;
        require(value >= _money + _amount);

        uint per = _money / _amount;
        require(per * _amount == _money);

        bytes memory convert = bytes(_key);
        require(convert.length != 0);

        bytes32 salt;
        assembly {
            salt := mload(add(convert, 32))
        }

        ChristmasStocking stocking = (new ChristmasStocking){value: value}(salt, _amount, _money);
        contains[_key] = true;
        presents[_key] = stocking;
        owners[_key] = msg.sender;
    }

    function participate(string calldata _key) external payable exists(_key) {
        presents[_key].participate();
    }

    function claim(string calldata _key) external exists(_key) {
        presents[_key].claim();
    }

}