// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklist is Ownable {
    mapping(address => bool) public isBlocked;

    function add(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (!isBlocked[addrs[i]]) {
                isBlocked[addrs[i]] = true;
            }
        }
    }

    function remove(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (isBlocked[addrs[i]]) {
                isBlocked[addrs[i]] = false;
            }
        }
    }
}
