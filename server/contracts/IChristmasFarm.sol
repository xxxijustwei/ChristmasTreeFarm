// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChristmasFarm {

    struct Socks {
        address creator;
        uint initAmount;
        uint initBalance;
        uint currentAmount;
        uint currentBalance;
        uint conditionBalance;
        bool isAverage;
    }

    event CreatePresentEvent(address indexed creator, string key);
    event ClaimedPresentEvent(address indexed sender, string key, uint value);

    error PresentInvalidValueError(string key, uint value);
    error PresentEmptyError(string key);
    error PresentNotExistsError(string key);
    error PresentAlreadyExistsError(string key);
    error PresentAlreadyClaimedError(string key);
    error PresentNotMeetConditionError(string key);

    function createPresent(string calldata _key, uint _amount, uint _cBalance, bool _average) external payable;
    function claimPresent(string calldata _key) external returns (uint);

    function getSentPresents() external view returns (string[] memory);
    function getPresentInfo(string calldata _key) external view returns (address, uint, uint, uint, uint, uint, bool);

    function getAccumSend() external view returns (uint);
    function getAccumClaim() external view returns (uint);

    function canClaim(string calldata _key) external view returns (bool);
}