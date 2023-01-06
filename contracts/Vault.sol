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
    function setTraits2(
        uint256 tokenId,
        uint8 race,
        uint8 attribute
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

    mapping(uint256 => Deposit) public tokenDeposits;
    mapping(uint256 => NFTDeposit) public nftDeposits;

    mapping(bytes32 => bool) public withdrawn;
    mapping(string => bool) public withdrawnForString;
    mapping(string => bool) public withdrawnForToken;
    mapping(address => bool) public isSupportedToken;

    event DepositToken(address indexed user, uint256 id, address token, uint256 amount, uint256 timestamp);
    event WithdrawToken(address indexed user, address token, uint256 amount, uint256 timestamp);

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
        require(msg.sender == admin, "Not admin");
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
        // IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit DepositToken(msg.sender, currentTokenDepositId, token, amount, block.timestamp);
    }

    function getNFTDeposits(uint256 id)
        public
        view
        returns (
            address user,
            address token,
            uint256[] memory tokenIds,
            uint256 timestamp
        )
    {
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
        // IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, token, amount, block.timestamp);
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

    // function withdrawNFT(
    //     uint256 id,
    //     WithdrawParams memory params,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) public onlySupportedToken(params.token) {
    //     require(block.timestamp < deadline, "Expired deadline");
    //     bytes32 hash = ECDSA.toEthSignedMessageHash(
    //         abi.encodePacked(id, msg.sender, params.token, params.tokenId, deadline)
    //     );
    //     require(!withdrawn[hash], "Already withdrawn");
    //     withdrawn[hash] = true;
    //     address recovered = ECDSA.recover(hash, v, r, s);
    //     require(recovered == signer, "Invalid signature");

    //     //IERC721(params.token).transferFrom(address(this), msg.sender, params.tokenId);

    //     emit WithdrawNFT(msg.sender, params.token, params.tokenId, block.timestamp);

    //     if(params.token == hero) {
    //         IHero(params.token).setTraits(params.tokenId, params.level, params.life, params.active); 
    //         IHero(params.token).setTraits2(params.tokenId, params.level, params.life, params.active); 
    //     }
    //     if (params.token == warrior) {
    //         IWarrior(params.token).setTraits(params.tokenId, params.life, params.active);
    //     }
    // }

    // function withdrawNFTs(
    //     uint256 id,
    //     WithdrawParams[] calldata paramsArray,
    //     uint256 deadline,
    //     uint8[] calldata vs,
    //     bytes32[] calldata rs,
    //     bytes32[] calldata ss
    // ) external {
    //     for (uint256 i = 0; i < paramsArray.length; i++) {
    //         withdrawNFT(id, paramsArray[i], deadline, vs[i], rs[i], ss[i]);
    //     }
    // }

    /*single*/

    address verifyAddress = 0xD41C1D568DC7E8a312E5fA24f700f5775ef88019;

    function withdrawNFTSingle(
        address owner,
        string memory id,
        address token,
        uint256 tokenId,
        uint8 race,
        uint8 attribute,
        uint8 level,
        uint16 life,
        bool active,
        string memory s,
        bytes memory signature
    ) public {
        require(!withdrawnForString[id], "Already withdrawn");
        withdrawnForString[id] = true;
        address recovered = checkRecover(msg.sender, id, token, tokenId, level, life, active, s, signature);
        require(recovered == verifyAddress, "Invalid signature");

        // IERC721(token).transferFrom(address(this), msg.sender,tokenId);

        emit WithdrawNFT(msg.sender, token, tokenId, block.timestamp);

        if (token == hero) {
            IHero(token).setTraits(tokenId, level, life, active);
            IHero(token).setTraits2(tokenId, race, attribute);
        }

        if (token == warrior) {
            IWarrior(token).setTraits(tokenId, life, active);
        }
    }

    function withdrawNFTSMultiple(
        address owner,
        string[] memory ids,
        address[] memory tokens,
        uint256[] memory tokenIds,
        uint8[] memory races,
        uint8[] memory attributes,
        uint8[] memory levels,
        uint16[] memory lifes,
        bool[] memory actives,
        string[] memory s,
        bytes[] memory signatures
    ) public {
        for (uint256 i = 0; i < ids.length; i++) {
            withdrawNFTSingle(
                owner,
                ids[i],
                tokens[i],
                tokenIds[i],
                races[i],
                attributes[i],
                levels[i],
                lifes[i],
                actives[i],
                s[i],
                signatures[i]
            );
        }
    }

    function withdrawSigle(
        string memory id,
        address token,
        uint256 amount,
        string memory s,
        bytes memory signature
    ) external {
        require(!withdrawnForToken[id], "Already withdrawn");
        withdrawnForToken[id] = true;
        address recovered = checkRecoverToken(msg.sender, id, token, amount, s, signature);
        require(recovered == signer, "Invalid signature");
        // IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, token, amount, block.timestamp);
    }

    /**
     *验证签名
     */
    function checkRecover(
        address owner,
        string memory id,
        address token,
        uint256 tokenId,
        uint8 level,
        uint16 life,
        bool active,
        string memory s,
        bytes memory signature
    ) public view returns (address) {
        bytes32 hash = toEthSignedMessageHash(owner, id, token, tokenId, level, life, active, s);
        (address voter, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        _throwError(error);

        require(verifyAddress == voter, "Validation failed");
        return voter;
    }

    /**
     *验证签名  token
     */
    function checkRecoverToken(
        address owner,
        string memory id,
        address token,
        uint256 amount,
        string memory s,
        bytes memory signature
    ) public view returns (address) {
        bytes32 hash = toEthSignedMessageHashToken(owner, id, token, amount, s);
        (address voter, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        _throwError(error);

        require(verifyAddress == voter, "Validation failed");
        return voter;
    }

    /**
     * 签名数据
     */
    function toEthSignedMessageHash(
        address owner,
        string memory id,
        address token,
        uint256 tokenId,
        uint8 level,
        uint16 life,
        bool active,
        string memory s
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(owner, id, token, tokenId, level, life, active, s));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", hash));
    }

    /**
     * 签名数据
     */
    function toEthSignedMessageHashToken(
        address owner,
        string memory id,
        address token,
        uint256 amount,
        string memory s
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(owner, id, token, amount, s));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", hash));
    }

    /**
     *异常
     */
    function _throwError(ECDSA.RecoverError error) private pure {
        if (error == ECDSA.RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == ECDSA.RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == ECDSA.RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == ECDSA.RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == ECDSA.RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /*single end*/
    /* 
        admin functions 
    */

    function adminWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyAdmin {
        IERC20(token).safeTransfer(to, amount);
    }

    function adminWithdrawNFTs(
        address token,
        uint256[] calldata tokenIds,
        address to
    ) external onlyAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).transferFrom(address(this), to, tokenIds[i]);
        }
    }
}
