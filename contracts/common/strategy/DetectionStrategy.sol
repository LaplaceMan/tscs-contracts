// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DetectionStrategy {
    uint256 public distanceThreshold;

    function _hammingDistance(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        // Get A XOR B...
        uint256 c = a ^ b;
        uint256 count = 0;
        while (c != 0) {
            // This works because if a number is power of 2,
            // then it has only one 1 in its binary representation.
            c = c & (c - 1);
            count++;
        }
        return count;
    }

    function detection(uint256 origin, uint256[] memory history)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < history.length; i++) {
            uint256 distance = _hammingDistance(origin, history[i]);
            if (distance <= distanceThreshold) {
                return false;
            }
        }
        return true;
    }
}
