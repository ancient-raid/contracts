// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandom {
  function random(uint256 _seed, uint256 _nonce) external view returns (uint256);
}
