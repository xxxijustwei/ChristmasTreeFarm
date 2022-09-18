// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {

    constructor(address _onwer) {
        _setupRole(DEFAULT_ADMIN_ROLE, _onwer);
    }

    modifier onlyOnwer() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You are not an authorized user.");
        _;
    }
}