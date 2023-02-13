// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBlacklist.sol";
import "./IRandom.sol";

contract Warrior is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    enum SpendCoin {
        Gold,
        Silver,
        Copper,
        Busd
    }

    struct Trait {
        uint8 race;
        uint8 attribute;
        bool active;
        uint16 life;
        uint256 power;
    }

    string public baseURI;
    uint256 private nonce;
    address public blacklist;
    mapping(uint256 => Trait) private traits;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isOperator;

    mapping(uint256 => uint256) public mintedAt;
    mapping(address => bool) public isAdmin;
    mapping(uint256 => bool) public isBlocked;
    
    address public _random;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("Raid Warrior", "WARRIOR");
    }

    function reinitialize() public reinitializer(2) {
        isAdmin[address(0xb5806BaC44B345A8505A90e1cEA9266a6A329129)] = true;
        isAdmin[address(0xCAB72Bf00ab85A1a2C2069CFb679e09b59d386Cb)] = true;
        isAdmin[address(0x7a38060d663d14f7441e6Cb1F1b4c1c0a113E68E)] = true;
        isAdmin[address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359)] = true;
    }

    function reinitialize3() public reinitializer(3) {
        _random = address(0x8951405238b1597cD824Ae50EB5077fc6c407b26);
    }

    function setRandom(address random_) external onlyOwner {
        _random = random_;
    }

    function setAdmin(address admin_, bool b_) external onlyOwner {
        isAdmin[admin_] = b_;
    }

    function setBlocked(uint256 tokenId, bool b_) external {
        require(isAdmin[_msgSender()], "Not admin");
        isBlocked[tokenId] = b_;
    }

    modifier checkBlacklisted(address operator) {
        require(!IBlacklist(blacklist).isBlocked(operator), "Warrior: Blocked operator");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function setBlacklist(address blacklist_) external onlyOwner {
        blacklist = blacklist_;
    }

    function setMinter(address minter_, bool b_) external onlyOwner {
        isMinter[minter_] = b_;
    }

    function setOperator(address operator_, bool b_) external onlyOwner {
        isOperator[operator_] = b_;
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


        if(spendCoin == SpendCoin.Busd) {
            if (seed < 400) {
                race = 1;
            } else if (seed >= 400 && seed < 650) {
                race = 2;
            } else if (seed >= 650 && seed < 850) {
                race = 3;
            } else if (seed >= 850 && seed < 950) {
                race = 4;
            } else {
                race = 5;
            }
            return race;
        }

        return race;
    }


    // （木35%>水25%>火20%>暗12%>光8%）
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

    function _calcPower(uint8 race) internal pure returns(uint256) {
        uint256 power = 10;
        if(race == 1) {
            power = 10;
        } else if(race == 2) {
            power = 20;
        } else if(race == 3) {
            power = 40;
        } else if(race == 4) {
            power = 50;
        } else if(race == 5) {
            power = 80;
        }
        return power;
    }

    function mint(address to, SpendCoin spendCoin) external {
        require(isMinter[_msgSender()], "Not minter");
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);
        uint256 rand = random(tokenId);
        uint8 race =  _generateRace((rand >> 240) % 1000, spendCoin);
        traits[tokenId] = Trait({
            race: race,
            attribute: _generateAttribute((rand & 0xffff) % 100),
            power: _calcPower(race),
            life: 30,
            active: false
        });

        mintedAt[tokenId] = block.timestamp;
    }

    // Human - 75%
    // Elf - 23%
    // Orc - 1%
    // Dragon - 1%
    // No God
    function mint3(address to) external {
        require(isMinter[_msgSender()], "Not minter");
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);
        uint256 rand = random(tokenId);
        uint256 seed = (rand >> 240) % 100;
        uint8 race = 1;
        if (seed < 75) {
            race = 1;
        } else if (seed >= 75 && seed < 98) {
            race = 2;
        } else if (seed >= 98 && seed < 99) {
            race = 3;
        } else if (seed >= 99) {
            race = 4;
        }
        traits[tokenId] = Trait({
            race: race,
            attribute: _generateAttribute((rand & 0xffff) % 100),
            power: _calcPower(race),
            life: 30,
            active: false
        });

        mintedAt[tokenId] = block.timestamp;
    }

    function getTraits(uint256 tokenId) public view returns (Trait memory) {
        _requireMinted(tokenId);
        return traits[tokenId];
    }

    function setTraits(
        uint256 tokenId,
        uint16 life,
        bool active
    ) external {
        require(isOperator[_msgSender()], "Not operator");
        traits[tokenId].life = life;
        traits[tokenId].active = active;
    }


    function random(uint256 seed) internal returns (uint256) {
        // return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, nonce++, seed)));
        return IRandom(_random).random(seed, ++nonce);
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
