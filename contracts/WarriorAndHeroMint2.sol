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
    function mint3(address to) external;
}


interface IHero {
    function mint3(address to) external;

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
    address public recipient = address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359);
 

    uint256 nonce;
    
    uint256 public busdPrice;

 

    mapping (IWarrior.SpendCoin => address) public paymentAddrs;
    mapping (IWarrior.SpendCoin => uint256) public prices;
    mapping (address => bool) public isOperator;

    

   mintInvate[]  public    clickIds;  
   struct mintInvate {
        address _user; 
        string _clickid;
    }

    constructor( 
        address busd_,
        address hero_,
        address warrior_ 
         
    ) {
       
        busd = busd_;
        hero = hero_;
        warrior = warrior_;
       
        busdPrice = 350 * 1e18; 

        isOperator[msg.sender] = true;
        isOperator[address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359)] = true;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
    }

  

    function setWarrior(address warrior_) external onlyOwner {
        warrior = warrior_;
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

    function getLength() public view returns (uint){
        return  clickIds.length; 
    }
  

  

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    function random() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, nonce++)));
    }

    function mint(uint256 count, string memory inviter) external onlyEOA {
       
       clickIds.push(mintInvate({_user:msg.sender,_clickid:inviter}));

        if(busdPrice > 0) {
            IERC20(busd).safeTransferFrom(msg.sender, recipient, busdPrice * count);
        } 
       

        
        for (uint256 i = 0; i < count*5; i++) { 
           IWarrior(warrior).mint3(msg.sender); 
        }

         for (uint256 i = 0; i < count; i++) {
            IHero(hero).mint3(msg.sender);
        }
    }

    
}
