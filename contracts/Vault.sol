// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IHero {
    function setTraits(
        uint256 tokenId,
        uint8 level,
        uint16 life,
        bool active
    ) external;
}

interface IWarrior {
    function setTraits(
        uint256 tokenId,
        uint16 life,
        bool active
    ) external;
}

contract Vault is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct Deposit {
        address user;
        address token;
        uint256 amount;
        uint256 timestamp;
    }

    struct NFTDeposit {
        address user;
        address token;
        uint256[] tokenIds;
        uint256 timestamp;
    }

    struct WithdrawParams {
        address token;
        uint256 tokenId;
        uint8 level;
        uint16 life;
        bool active;
    }

    uint256 public currentTokenDepositId;
    uint256 public currentNFTDepositId;

    address public admin;
    address public signer;

    address public hero;
    address public warrior;

    mapping (uint256 => Deposit) public tokenDeposits;
    mapping (uint256 => NFTDeposit) public nftDeposits;

    mapping (bytes32 => bool) public withdrawn;
    mapping (address => bool) public isSupportedToken;
    

    event DepositToken(address indexed user, uint256 id, address token, uint256 amount, uint256 timestamp);
    event WithdrawToken(address indexed user, uint256 id, address token, uint256 amount, uint256 timestamp);

    event DepositNFT(address indexed user, address token, uint256[] tokenId, uint256 timestamp);
    event WithdrawNFT(address indexed user, address token, uint256 tokenId, uint256 timestamp);

    function initialize() public initializer {
        __Ownable_init();
        currentTokenDepositId = 0;
        currentNFTDepositId = 0;
        isSupportedToken[address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = true; // BUSD
        isSupportedToken[address(0xeb90A6273F616A8ED1cf58A05d3ae1C1129b4DE6)] = true; // RAID
        isSupportedToken[address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8)] = true; // Hero NFT
        isSupportedToken[address(0x0d9eb3079Dbf1Df9715B47DA98a3BacaeD28c49C)] = true; // Warrior NFT
    }

    function setAdmin(address admin_) external onlyOwner {
        admin = admin_;
    }

    function setSupportToken(address token, bool supported) external onlyOwner {
        isSupportedToken[token] = supported;
    }


    modifier onlyAdmin() { 
        require (msg.sender == admin, "Not admin"); 
        _; 
    }

    modifier onlySupportedToken(address token) { 
        require(isSupportedToken[token], "Invalid token");
        _; 
    }
    
    function deposit(address token, uint256 amount) external onlySupportedToken(token) {
        require(amount > 0, "Amount is zero");
        tokenDeposits[++currentTokenDepositId] = Deposit({
            user: msg.sender,
            token: token,
            amount: amount,
            timestamp: block.timestamp
        });
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit DepositToken(msg.sender, currentTokenDepositId, token, amount, block.timestamp);
    }

    function getNFTDeposits(uint256 id) public view returns(
        address user,
        address token,
        uint256[] memory tokenIds,
        uint256 timestamp
    ) {
        user = nftDeposits[id].user;
        token = nftDeposits[id].token;
        tokenIds = nftDeposits[id].tokenIds;
        timestamp = nftDeposits[id].timestamp;
    }

    function withdraw(
        uint256 id,
        address token, 
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlySupportedToken(token) {
        require(block.timestamp < deadline, "Expired deadline");
        bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked(id, msg.sender, token, amount, deadline));
        require(!withdrawn[hash], "Already withdrawn");
        withdrawn[hash] = true;
        address recovered = ECDSA.recover(hash, v, r, s);
        require(recovered == signer, "Invalid signature");
        IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, id, token, amount, block.timestamp);
    }

    function depositNFTs(address token, uint256[] calldata tokenIds) external onlySupportedToken(token){
        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        nftDeposits[++currentNFTDepositId] = NFTDeposit({
            user: msg.sender,
            token: token,
            tokenIds: tokenIds,
            timestamp: block.timestamp
        });

        emit DepositNFT(msg.sender, token, tokenIds, block.timestamp);
    }

    function withdrawNFT( 
        uint256 id,
        WithdrawParams memory params,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlySupportedToken(params.token) {
        require(block.timestamp < deadline, "Expired deadline");
        bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked(id, msg.sender, params.token, params.tokenId, deadline));
        require(!withdrawn[hash], "Already withdrawn");
        withdrawn[hash] = true;
        address recovered = ECDSA.recover(hash, v, r, s);
        require(recovered == signer, "Invalid signature");

        IERC721(params.token).transferFrom(address(this), msg.sender, params.tokenId);

        emit WithdrawNFT(msg.sender, params.token, params.tokenId, block.timestamp);

        if(params.token == hero) {
            IHero(params.token).setTraits(params.tokenId, params.level, params.life, params.active); 
        }
        if(params.token == warrior) {
            IWarrior(params.token).setTraits(params.tokenId, params.life, params.active); 
        }
    }

    function withdrawNFTs(
        uint256 id,
        WithdrawParams[] calldata paramsArray,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        for(uint256 i = 0; i < paramsArray.length; i++) {
            withdrawNFT(id, paramsArray[i], deadline, vs[i], rs[i], ss[i]);
        }
    }

    /* 
        admin functions 
    */

    function adminWithdraw(address token, uint256 amount, address to) external onlyAdmin {
        IERC20(token).safeTransfer(to, amount);
    }

    function adminWithdrawNFTs(address token, uint256[] calldata tokenIds, address to) external onlyAdmin {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).transferFrom(address(this), to, tokenIds[i]);
        }
    }
}
