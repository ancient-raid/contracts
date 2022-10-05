// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBlacklist {
    function isBlocked(address) external view returns (bool);
}
