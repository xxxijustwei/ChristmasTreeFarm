// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IChristmasFarm {

    struct Socks {
        address creator;
        uint initAmount;
        uint initBalance;
        uint currentAmount;
        uint currentBalance;
        bool isAverage;
    }

    event CreatePresentEvent(address indexed creator, string indexed key);
    event ClaimedPresentEvent(address indexed sender, string indexed key, uint value);

    error PresentInvalidValue(string key, uint value);
    error PresentEmpty(string key);
    error PresentNotExists(string key);
    error PresentAlreadyExists(string key);
    error PresentAlreadyClaimed(string key);
    error PresentAlreadyParticipate(string key);

    error NotEnoughFee(uint vlaue, uint required);
    error DepositTooLow(uint value, uint required);

    function create(string calldata _key, uint _amount, bool _average) external payable;
    function participate(string calldata _key) external payable;
    function claim(string calldata _key) external returns (uint);

    function getSentPresents() external view returns (string[] memory);
    function getPresentInfo(string calldata _key) external view returns (address, uint, uint, uint, uint, bool);

    function getAccumSend() external view returns (uint);
    function getAccumClaim() external view returns (uint);

    function canClaim(string calldata _key) external view returns (bool);
}