// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IBlacklist.sol";

contract Hero is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    struct Trait {
        uint8 race;
        uint8 attribute;
        uint8 level;
        uint16 life;
        bool active;
    }

    string public baseURI;
    address public blacklist;
    uint256 private nonce;
    mapping(uint256 => Trait) private traits;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isOperator;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("Raid Hero", "HERO");

        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = totalSupply() + 1;
            _mint(address(0x2791669e23A3Aee19d9906CFfAA1C83939c9BeC2), tokenId);
            traits[tokenId] = Trait({ race: 5, attribute: 5, level: 1, life: 300, active: false });
        }

        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = totalSupply() + 1;
            _mint(address(0x2791669e23A3Aee19d9906CFfAA1C83939c9BeC2), tokenId);
            traits[tokenId] = Trait({ race: 5, attribute: 4, level: 1, life: 300, active: false });
        }
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

    function setOperator(address operator_, bool b_) external onlyOwner {
        isOperator[operator_] = b_;
    }

    function setBlacklist(address blacklist_) external onlyOwner {
        blacklist = blacklist_;
    }

    modifier checkBlacklisted(address operator) {
        require(!IBlacklist(blacklist).isBlocked(operator), "Hero: Blocked operator");
        _;
    }

    function _generateAttribute(uint256 seed) internal pure returns (uint8) {
        uint8 attribute;
        if (seed < 35) {
            attribute = 1;
        } else if (seed >= 35 && seed < 60) {
            attribute = 2;
        } else if (seed >= 60 && seed < 80) {
            attribute = 3;
        } else if (seed >= 80 && seed < 92) {
            attribute = 4;
        } else {
            attribute = 5;
        }
        return attribute;
    }

    function mint(address to) external {
        require(isMinter[_msgSender()], "Not minter");
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);

        uint256 rand = random(tokenId);
        uint256 seed = (rand >> 240) % 100;
        uint8 race;
        if (seed < 40) {
            race = 1;
        } else if (seed >= 40 && seed < 65) {
            race = 2;
        } else if (seed >= 65 && seed < 85) {
            race = 3;
        } else if (seed >= 85 && seed < 95) {
            race = 4;
        } else {
            race = 5;
        }

        traits[tokenId] = Trait({
            race: race,
            attribute: _generateAttribute((rand & 0xffff) % 100),
            level: 1,
            life: 300,
            active: false
        });
    }

    function mintByGold(address to) external {
        require(isMinter[_msgSender()], "Not minter");
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);

        uint256 rand = random(tokenId);
        uint256 seed = (rand >> 240) % 100;
        uint8 race;
        if (seed < 50) {
            race = 1;
        } else if (seed >= 50 && seed < 75) {
            race = 2;
        } else if (seed >= 75 && seed < 92) {
            race = 3;
        } else if (seed >= 92 && seed < 99) {
            race = 4;
        } else {
            race = 5;
        }

        traits[tokenId] = Trait({
            race: race,
            attribute: _generateAttribute((rand & 0xffff) % 100),
            level: 1,
            life: 300,
            active: false
        });
    }

    function setTraits(
        uint256 tokenId,
        uint8 level,
        uint16 life,
        bool active
    ) external {
        require(isOperator[_msgSender()], "Not operator");
        traits[tokenId].level = level;
        traits[tokenId].life = life;
        traits[tokenId].active = active;
    }

    function getTraits(uint256 tokenId) public view returns (Trait memory) {
        _requireMinted(tokenId);
        return traits[tokenId];
    }

    function random(uint256 seed) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, nonce++, seed)));
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal override checkBlacklisted(operator) {
        super._setApprovalForAll(owner, operator, approved);
    }

    function _approve(address to, uint256 tokenId) internal override checkBlacklisted(to) {
        super._approve(to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        checkBlacklisted(spender)
        returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }
}
