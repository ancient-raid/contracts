// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWarrior {
    enum SpendCoin {
        Gold,
        Silver,
        Copper,
        Busd
    }
    function mint(address to, SpendCoin spendCoin) external;
}


interface IHero {
    function mint(address to) external;

    function mintByGold(address to) external;
}

interface IBlackCard is IERC721Enumerable {
    function mint(address to) external;
}

interface IInvitation {
    function inviteForWarrior(
        address _invitee,
        address _inviter,
        uint256 count
    ) external;
}

contract WarriorAndHeroMint is Ownable {
    using SafeERC20 for IERC20;

    address public hero;
    address public busd;
    address public warrior;
    address public blackCard;
    address public recipient = address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359);
    address public invitation = address(0x6bAEf88ea37eEDE9f6407A4dE2BF81f3D4035A3A);

    uint256 nonce;
    
    uint256 public busdPrice;

    bool blackCardEnabled = true;

    mapping (IWarrior.SpendCoin => address) public paymentAddrs;
    mapping (IWarrior.SpendCoin => uint256) public prices;
    mapping (address => bool) public isOperator;
    

    constructor( 
        address busd_,
        address hero_,
        address warrior_,
        address blackCard_ 
    ) {
       
        busd = busd_;
        hero = hero_;
        warrior = warrior_;
        blackCard = blackCard_;  
        busdPrice = 1 * 1e18; 

        isOperator[msg.sender] = true;
        isOperator[address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359)] = true;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
    }

    function setInvitation(address invitation_) external onlyOwner {
        invitation = invitation_;
    }

    function setWarrior(address warrior_) external onlyOwner {
        warrior = warrior_;
    }

    function setBlackCard(address blackCard_) external onlyOwner {
        blackCard = blackCard_;
    }

    function setOperator(address operator_, bool b_) external onlyOwner {
        isOperator[operator_] = b_;
    }

    function setCoinPrice(IWarrior.SpendCoin spendCoin, uint256 price) external {
        require(isOperator[msg.sender], "Not operator");
        prices[spendCoin] = price;
    }

    function setBusdPrice(uint256 price_) external {
        require(isOperator[msg.sender], "Not operator");
        busdPrice = price_;
    }

   

    function setBlackCardEnabled(bool b_) external {
        require(isOperator[msg.sender], "Not operator");
        blackCardEnabled = b_;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    function random() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, nonce++)));
    }

    function mint(uint256 count, address inviter) external onlyEOA {
        if (invitation != address(0)) {
            IInvitation(invitation).inviteForWarrior(msg.sender, inviter, count);
        }

        if(busdPrice > 0) {
            IERC20(busd).safeTransferFrom(msg.sender, recipient, busdPrice * count);
        } 
       

        bool flag = false;
        for (uint256 i = 0; i < count*5; i++) {
            if(flag) {
                IWarrior(warrior).mint(msg.sender, IWarrior.SpendCoin.Busd);
            } else {
                uint256 total = IBlackCard(blackCard).totalSupply();
                uint256 rand = random();
                if(blackCardEnabled && rand % 1000 < 1 && total < 100) {
                    IBlackCard(blackCard).mint(msg.sender);
                    flag = true;
                } else {
                    IWarrior(warrior).mint(msg.sender, IWarrior.SpendCoin.Busd);
                }
            }
        }

         for (uint256 i = 0; i < count; i++) {
            IHero(hero).mint(msg.sender);
        }
    }

    
}
