// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IHero {
    function mint(address to) external;

    function mintByGold(address to) external;
}

interface IInvitation {
    function invite(
        address _invitee,
        address _inviter,
        uint256 count
    ) external;
}

contract HeroMint is Ownable {
    using SafeERC20 for IERC20;

    address public hero;
    address public busd;
    address public raid;
    address public gold;
    address public recipient = address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359);
    address public invitation = address(0xBAED839291A28CbB02C31aE268a8797D02a4c0de);

    uint256 public busdPrice = 75 * 1e18;
    uint256 public raidPrice = 0 * 1e18;
    uint256 public goldPrice = 1 * 1e18;

    mapping(address => bool) public whiltelisted;
    mapping(address => bool) public wlMinted;

    constructor(
        address hero_,
        address busd_,
        address raid_,
        address gold_
    ) {
        hero = hero_;
        busd = busd_;
        raid = raid_;
        gold = gold_;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
    }

    function setInvitation(address invitation_) external onlyOwner {
        invitation = invitation_;
    }

    function setHero(address hero_) external onlyOwner {
        hero = hero_;
    }

    function setBusdPrice(uint256 price_) external onlyOwner {
        busdPrice = price_;
    }

    function setRaidPrice(uint256 price_) external onlyOwner {
        raidPrice = price_;
    }

    function setGoldPrice(uint256 price_) external onlyOwner {
        goldPrice = price_;
    }

    function addWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (!whiltelisted[addrs[i]]) {
                whiltelisted[addrs[i]] = true;
            }
        }
    }

    function removeWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (whiltelisted[addrs[i]]) {
                whiltelisted[addrs[i]] = false;
            }
        }
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    function whitelistMint() external onlyEOA {
        require(whiltelisted[msg.sender], "Not whitelisted");
        require(!wlMinted[msg.sender], "Minted");
        wlMinted[msg.sender] = true;
        IHero(hero).mint(msg.sender);
    }

    function mint(uint256 count, address inviter) external onlyEOA {
        if (invitation != address(0)) {
            IInvitation(invitation).invite(msg.sender, inviter, count);
        }
        IERC20(busd).safeTransferFrom(msg.sender, recipient, busdPrice * count);
        if (raidPrice > 0) {
            IERC20(raid).safeTransferFrom(msg.sender, recipient, raidPrice * count);
        }
        for (uint256 i = 0; i < count; i++) {
            IHero(hero).mint(msg.sender);
        }
    }

    function mintByGold(uint256 count) external onlyEOA {
        IERC20(gold).safeTransferFrom(msg.sender, recipient, goldPrice * count);
        for (uint256 i = 0; i < count; i++) {
            IHero(hero).mintByGold(msg.sender);
        }
    }
}
