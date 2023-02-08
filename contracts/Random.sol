// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRandom.sol";


interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract Random is IRandom, Ownable{
  //  BNB_BUSD = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16
  address pair; 

  constructor() {
    pair = address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
  }

  function setPair(address pair_) external onlyOwner{
    pair = pair_;
  }

  function getPrice() internal view returns(uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair).getReserves();
    return uint256(reserve0 > reserve1 ? reserve0 / reserve1 : reserve1 / reserve0);
  }

  function random(uint256 _seed, uint256 _nonce) public view override returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_seed, _nonce, blockhash(block.number - 1), block.timestamp, getPrice(), tx.origin)));
  }
}
