// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SafeMath8 {
    function mulUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

    function divUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint8 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
        return c;
    }

    function subUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

    function addUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }
}
