// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Warrior is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    enum SpendCoin {
        Copper,
        Silver,
        Gold
    }

    struct Trait {
        uint8 race;
        uint8 attribute;
        uint8 level;
        uint16 life;
    }

    uint256 private nonce;
    mapping(uint256 => Trait) private traits;
    mapping(address => bool) public isMinter;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("Raid Warrior", "WARRIOR");
    }

    function setMinter(address minter_, bool b_) external onlyOwner {
        isMinter[minter_] = b_;
    }

    function _generateRace(uint256 seed, SpendCoin spendCoin) internal pure returns (uint8) {
        uint8 race;

        // 銅幣
        // 人89.9%
        // 妖10%
        // 獸0.1%

        if (spendCoin == SpendCoin.Copper) {
            // mint by copper
            if (seed < 899) {
                race = 1;
            } else if (seed >= 899 && seed < 999) {
                race = 2;
            } else {
                race = 3;
            }
            return race;
        }
        // 銀幣
        // 人69%
        // 妖20%
        // 獸10%
        // 龍1%
        if (spendCoin == SpendCoin.Silver) {
            // mint by silver
            if (seed < 690) {
                race = 1;
            } else if (seed >= 690 && seed < 890) {
                race = 2;
            } else if (seed >= 890 && seed < 990) {
                race = 3;
            } else {
                race = 4;
            }
            return race;
        }

        // 金幣
        // 人50%
        // 妖25%
        // 獸17%
        // 龍7%
        // 神1%
        if (spendCoin == SpendCoin.Gold) {
            // mint by gold
            if (seed < 500) {
                race = 1;
            } else if (seed >= 500 && seed < 750) {
                race = 2;
            } else if (seed >= 750 && seed < 920) {
                race = 3;
            } else if (seed >= 920 && seed < 990) {
                race = 4;
            } else {
                race = 5;
            }
            return race;
        }

        return race;
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

    function mint(address to, SpendCoin spendCoin) external {
        require(isMinter[_msgSender()], "Not minter");
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);
        uint256 rand = random(tokenId);
        traits[tokenId] = Trait({
            race: _generateRace((rand >> 240) % 1000, spendCoin),
            attribute: _generateAttribute((rand & 0xffff) % 100),
            level: 1,
            life: 300
        });
    }

    function random(uint256 seed) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, nonce++, seed)));
    }
}
