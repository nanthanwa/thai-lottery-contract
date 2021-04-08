// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Utils {
    constructor() public {}

    function numberToBytes(uint8[6] memory _numbers)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_numbers);
    }

    function bytesToNumber(bytes memory _numbers)
        public
        pure
        returns (uint8[6] memory)
    {
        uint8[6] memory numbers;
        (numbers) = abi.decode(_numbers, (uint8[6]));
        return numbers;
    }
}
