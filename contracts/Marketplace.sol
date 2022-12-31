// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC721TokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IRaidNFT {
    function isBlocked(uint256) external view returns (bool);
    function mintedAt(uint256) external view returns (uint256);
}


contract Marketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Order {
        uint256 id;
        address nftAddr;
        uint256 nftId;
        uint256 price;
        uint256 createdAt;
        address owner;
    }

    uint256 public nextOrderId;
    uint256 public fee;
    uint256 public feeMax;
    uint256 public floorPrice;
    address payable feeTo;

    IERC20 public paymentToken;

    uint256[] public orderIds;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => uint256) orderIdIndexes;
    mapping(address => uint256[]) public userOrderIds;
    mapping(address => mapping(uint256 => uint256)) userOrderIdIndexes;
    mapping(address => bool) public supportedNfts;
    mapping(address => bool) public isOperator;

    event CreateOrder(address indexed user, address nftAddr, uint256 nftId, uint256 price);
    event CancelOrder(address indexed user, address nftAddr, uint256 nftId);
    event Buy(address indexed buyer, address indexed seller, address nftAddr, uint256 nftId, uint256 price);
    event ChangePrice(address indexed user, address nftAddr, uint256 nftId, uint256 newPrice);

    mapping(address => uint256) public floorPrices;

    mapping(address => bool) isRaidNFT;

    uint256 public cooldown;


    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        fee = 100;
        feeMax = 1000;
        nextOrderId = 1;
        paymentToken = IERC20(address(0xeb90A6273F616A8ED1cf58A05d3ae1C1129b4DE6));
        supportedNfts[address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8)] = true;
    }

    function reinitialize() public reinitializer(2) {
        isOperator[address(0xb5806BaC44B345A8505A90e1cEA9266a6A329129)] = true;
        isOperator[address(0xCAB72Bf00ab85A1a2C2069CFb679e09b59d386Cb)] = true;
        isOperator[address(0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359)] = true;
        isOperator[address(0x62d9bF5544314b3fC46E2Aa4Fd661C2213d1Ec1A)] = true;
    }

    function reinitialize3() public reinitializer(3) {
        floorPrices[address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8)] = floorPrice;
    }

    function reinitialize4() public reinitializer(4) {
        isRaidNFT[address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8)] = true;
        isRaidNFT[address(0x0d9eb3079Dbf1Df9715B47DA98a3BacaeD28c49C)] = true;
        cooldown = 12 * 3600;
    }

    function setRaidNFT(address nftAddr_, bool b_) external onlyOwner {
        isRaidNFT[nftAddr_] = b_;
    }

    function setCooldown(uint256 cooldown_) external onlyOwner {
        cooldown = cooldown_;
    }

    function checkBlocked(address nftAddr_, uint256 nftId_) internal view {
        if(isRaidNFT[nftAddr_]) {
            require(!IRaidNFT(nftAddr_).isBlocked(nftId_), "Blocked NFT");
        }
    }

    function checkList(address nftAddr_, uint256 nftId_) internal view {
        if(isRaidNFT[nftAddr_]) {
            require(IRaidNFT(nftAddr_).mintedAt(nftId_) + cooldown < block.timestamp, "Not allowed to list now");
        }
    }

    function setOperator(address operator_, bool b_) external onlyOwner {
        isOperator[operator_] = b_;
    }

    function setFloorPrice(uint256 price_) external {
        require(isOperator[msg.sender], "Not operator");
        floorPrice = price_;
        floorPrices[address(0x38Fd96AFe66CD14a81787077fb90e93944Dd75f8)] = floorPrice;
    }

    function setFloorPriceV2(address nftAddr_, uint256 price_) external {
        require(isOperator[msg.sender], "Not operator");
        floorPrices[nftAddr_] = price_;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeTo(address payable _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function addNFT(address nftAddr) external onlyOwner {
        supportedNfts[nftAddr] = true;
    }

    function removeNFT(address nftAddr) external onlyOwner {
        supportedNfts[nftAddr] = false;
    }

    function createOrder(
        address nftAddr,
        uint256 nftId,
        uint256 price
    ) public nonReentrant {
        require(price >= floorPrices[nftAddr], "Price is lower than floor price");
        require(supportedNfts[nftAddr], "Not supported NFT");
        checkBlocked(nftAddr, nftId);
        checkList(nftAddr, nftId);

        address owner = IERC721(nftAddr).ownerOf(nftId);
        require(owner == msg.sender, "Not owner");
        require(price > 0, "Price is 0");
        IERC721(nftAddr).transferFrom(msg.sender, address(this), nftId);
        orders[nextOrderId] = Order({
            id: nextOrderId,
            nftAddr: nftAddr,
            nftId: nftId,
            price: price,
            createdAt: block.timestamp,
            owner: owner
        });

        orderIdIndexes[nextOrderId] = orderIds.length;
        orderIds.push(nextOrderId);

        userOrderIdIndexes[msg.sender][nextOrderId] = userOrderIds[msg.sender].length;
        userOrderIds[msg.sender].push(nextOrderId);

        nextOrderId++;

        emit CreateOrder(msg.sender, nftAddr, nftId, price);
    }

    function _removeOrder(uint256 orderId) internal {
        Order memory order = orders[orderId];

        uint256 lastOrderId = orderIds[orderIds.length - 1];
        orderIds[orderIdIndexes[orderId]] = lastOrderId;
        orderIds.pop();
        orderIdIndexes[lastOrderId] = orderIdIndexes[orderId];
        delete orderIdIndexes[orderId];

        uint256[] storage userOrderIdArray = userOrderIds[order.owner];
        uint256 lastUserOrderId = userOrderIdArray[userOrderIdArray.length - 1];
        uint256 userOrderIdIndex = userOrderIdIndexes[order.owner][order.id];
        userOrderIdArray[userOrderIdIndex] = lastUserOrderId;
        userOrderIdArray.pop();
        userOrderIdIndexes[order.owner][lastUserOrderId] = userOrderIdIndex;
        delete userOrderIdIndexes[order.owner][order.id];

        delete orders[orderId];
    }

    function cancelOrder(uint256 orderId) public nonReentrant {
        Order storage order = orders[orderId];
        require(order.id > 0, "Invalid OrderId");
        require(msg.sender == order.owner, "Not NFT Owner");
        IERC721(order.nftAddr).transferFrom(address(this), order.owner, order.nftId);
        emit CancelOrder(msg.sender, order.nftAddr, order.nftId);
        _removeOrder(orderId);
    }

    function buy(uint256 orderId) public nonReentrant {
        Order storage order = orders[orderId];
        require(order.id > 0, "Invalid OrderId");
        checkBlocked(order.nftAddr, order.nftId);
        uint256 protocolFee = (order.price * fee) / feeMax;

        paymentToken.transferFrom(msg.sender, order.owner, order.price - protocolFee);
        paymentToken.transferFrom(msg.sender, feeTo, protocolFee);
        IERC721(order.nftAddr).transferFrom(address(this), msg.sender, order.nftId);

        emit Buy(msg.sender, order.owner, order.nftAddr, order.nftId, order.price);
        _removeOrder(orderId);
    }

    function changePrice(uint256 orderId, uint256 price) public nonReentrant {
        Order storage order = orders[orderId];
        require(price >= floorPrices[order.nftAddr], "Price is lower than floor price");
        require(order.id > 0, "Invalid OrderId");
        require(order.price != price, "Same price");
        require(msg.sender == order.owner, "Not NFT Owner");
        order.price = price;
        emit ChangePrice(msg.sender, order.nftAddr, order.nftId, price);
    }

    function getUserOrderIds(address user) public view returns (uint256[] memory) {
        return userOrderIds[user];
    }

    function getOrderIds() public view returns (uint256[] memory) {
        return orderIds;
    }

    function ordersCount() public view returns (uint256) {
        return orderIds.length;
    }

    function userOrdersCount(address user) public view returns (uint256) {
        return userOrderIds[user].length;
    }

    function getOrder(uint256 _id)
        public
        view
        returns (
            uint256 id,
            address nftAddr,
            uint256 nftId,
            uint256 price,
            uint256 createdAt,
            address owner,
            string memory tokenURI,
            bool blocked
        )
    {
        Order memory order = orders[_id];
        id = order.id;
        nftAddr = order.nftAddr;
        nftId = order.nftId;
        price = order.price;
        createdAt = order.createdAt;
        owner = order.owner;
        tokenURI = IERC721TokenURI(nftAddr).tokenURI(nftId);

        if(isRaidNFT[order.nftAddr]) {
            blocked = IRaidNFT(order.nftAddr).isBlocked(order.nftId);
        } else {
            blocked = false;
        }
    }

    function getOrderByIndex(uint256 index)
        public
        view
        returns (
            uint256 id,
            address nftAddr,
            uint256 nftId,
            uint256 price,
            uint256 createdAt,
            address owner,
            string memory tokenURI,
            bool blocked
        )
    {
        return getOrder(orderIds[index]);
    }

    function getUserOrderByIndex(address user, uint256 index)
        public
        view
        returns (
            uint256 id,
            address nftAddr,
            uint256 nftId,
            uint256 price,
            uint256 createdAt,
            address owner,
            string memory tokenURI,
            bool blocked
        )
    {
        return getOrder(userOrderIds[user][index]);
    }
}
