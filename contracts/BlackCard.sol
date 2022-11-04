// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackCard is ERC721Enumerable, Ownable {
	string public baseURI;
	mapping(address => bool) public isMinter;

	constructor() ERC721("Raid BlackCard", "BLACKCARD") {
		baseURI = "https://metadata.ancientraid.com/blackcard/metadata/";
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function setBaseURI(string memory uri_) external onlyOwner {
      baseURI = uri_;
  }

  function setMinter(address minter_, bool b_) external onlyOwner {
  	isMinter[minter_] = b_;
  }

  function mint(address to) external {
  	require(isMinter[_msgSender()], "Not minter");
  	uint256 tokenId = totalSupply() + 1;
    _mint(to, tokenId);
  }
}