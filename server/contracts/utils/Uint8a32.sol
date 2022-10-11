// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

library Uint8a32 {
    uint constant bits = 8;
    uint constant elements = 32;

    uint constant range = 1 << bits;
    uint constant max = range - 1;

    function get(uint va, uint index) internal pure returns (uint) {
        require(index < elements);
        return (va >> (bits * index)) & max;
    }

    function set(uint va, uint index, uint ev) internal pure returns (uint) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return (va & ~(max << index)) | (ev << index);
    }
}