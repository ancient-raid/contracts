// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHero is IERC721Upgradeable {
    struct Trait {
        uint8 race;
        uint8 attribute;
        uint8 level;
        uint16 life;
        bool active;
    }

    function getTraits(uint256 tokenId) external view returns (Trait memory);
}

// 英雄质押设定我再写下：
// 1. 产出按照币安链的区块产出，据我所知1天有28800区块，每3秒1个区块
// 2. 每个英雄的产出不同，分别为：
// - 人族 ： 0.0001 Raid 每区块
// - 仙族 ： 0.00016 Raid 每区块
// - 兽族 ： 0.0002 Raid 每区块
// - 龙族 ： 0.0004 Raid 每区块
// - 神族 ： 0.0008Raid 每区块
// 3. 玩家随时可以提领退出质押
// 4. 产出可以随时调整
// 5. 第一期先定30天，第二期看看价位再做调整

contract StakingPhase1 is OwnableUpgradeable {
    IHero public hero;
    IERC20 public raid;
    address public treasury;
    uint256 public startBlock;
    uint256 public endBlock;

    mapping(uint8 => uint256) private rewardRates;
    mapping(uint256 => uint256) public staked;

    mapping(address => uint256[]) public userStakes;
    mapping(uint256 => uint256) public userStakeIndexes;

    function initialize() public initializer {
        rewardRates[1] = 0.0001 * 1e18;
        rewardRates[2] = 0.00016 * 1e18;
        rewardRates[3] = 0.0002 * 1e18;
        rewardRates[4] = 0.0004 * 1e18;
        rewardRates[5] = 0.0008 * 1e18;
        hero = IHero(address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8));
        raid = IERC20(address(0xeb90A6273F616A8ED1cf58A05d3ae1C1129b4DE6));
    }

    function reinitialize() public reinitializer(2) {
        __Ownable_init();
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setRewardBlocks(uint256 startBlock_, uint256 endBlock_) external onlyOwner {
        require(startBlock_ < endBlock_, "endBlock must be greater than startBlock");
        startBlock = startBlock_;
        endBlock = endBlock_;
    }

    function updateRewardRate(uint8 race, uint256 rewardRate) external onlyOwner {
        require(race >= 1 && race <= 5, "Invalid race");
        rewardRates[race] = rewardRate;
    }

    function getRace(uint256 tokenId) public view returns (uint8) {
        return hero.getTraits(tokenId).race;
    }

    function getRewardRates() public view returns (uint256[] memory rates) {
        rates = new uint256[](5);
        rates[0] = rewardRates[1];
        rates[1] = rewardRates[2];
        rates[2] = rewardRates[3];
        rates[3] = rewardRates[4];
        rates[4] = rewardRates[5];
    }

    function getUserStakesLength(address user) public view returns (uint256) {
        return userStakes[user].length;
    }

    function getUserStakes(address user) public view returns (uint256[] memory) {
        return userStakes[user];
    }

    function getPendingRewards(address user) public view returns (uint256) {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            totalRewards += getHeroRewards(userStakes[user][i]);
        }
        return totalRewards;
    }

    function getHeroRewards(uint256 tokenId) public view returns (uint256) {
        uint256 rewardsPerBlock = rewardRates[getRace(tokenId)];
        if (staked[tokenId] == 0) {
            return 0;
        }

        if (block.number < startBlock) {
            return 0;
        } else if (staked[tokenId] < startBlock && block.number <= endBlock) {
            return (block.number - startBlock) * rewardsPerBlock;
        } else if (staked[tokenId] > startBlock && block.number <= endBlock) {
            return (block.number - staked[tokenId]) * rewardsPerBlock;
        } else if (staked[tokenId] < endBlock && block.number > endBlock) {
            return (endBlock - staked[tokenId]) * rewardsPerBlock;
        } else {
            return 0;
        }
    }

    function stakeMany(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(hero.ownerOf(tokenIds[i]) == msg.sender, "Not owner");
            if (staked[tokenIds[i]] == 0) {
                staked[tokenIds[i]] = block.number;
                hero.transferFrom(msg.sender, address(this), tokenIds[i]);
                userStakeIndexes[tokenIds[i]] = userStakes[msg.sender].length;
                userStakes[msg.sender].push(tokenIds[i]);
            }
        }
    }

    function checkStakedOwner(uint256 tokenId) internal view returns (bool) {
        uint256 index = userStakeIndexes[tokenId];
        if (index > userStakes[msg.sender].length - 1) {
            return false;
        }
        return userStakes[msg.sender][index] == tokenId;
    }

    function unstakeMany(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(checkStakedOwner(tokenIds[i]), "Not staker");
            require(staked[tokenIds[i]] > 0, "Not staked");
            totalRewards += getHeroRewards(tokenIds[i]);
            staked[tokenIds[i]] = 0;

            uint256 lastTokenId = userStakes[msg.sender][userStakes[msg.sender].length - 1];
            if (lastTokenId == tokenIds[i]) {
                userStakes[msg.sender].pop();
                delete userStakeIndexes[tokenIds[i]];
            } else {
                // uint256 index = userStakes[msg.sender][userStakeIndexes[tokenIds[i]]];
                uint256 index = userStakeIndexes[tokenIds[i]];
                userStakeIndexes[lastTokenId] = index;
                userStakes[msg.sender][index] = lastTokenId;
                userStakes[msg.sender].pop();
                delete userStakeIndexes[tokenIds[i]];
            }
            hero.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        sendRewards(msg.sender, totalRewards);
    }

    function claimMany(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(checkStakedOwner(tokenIds[i]), "Not staker");
            require(staked[tokenIds[i]] > 0, "Not staked");
            totalRewards += getHeroRewards(tokenIds[i]);
            staked[tokenIds[i]] = block.number;
        }
        sendRewards(msg.sender, totalRewards);
    }

    function sendRewards(address to, uint256 amount) internal {
        if (amount > 0) {
            raid.transferFrom(treasury, to, amount);
        }
    }
}
