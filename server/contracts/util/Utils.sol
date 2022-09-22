// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {

    // unsafe
    function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

}