// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC721TokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

    function setOperator(address operator_, bool b_) external onlyOwner {
        isOperator[operator_] = b_;
    }

    function setFloorPrice(uint256 price_) external {
        require(isOperator[msg.sender], "Not operator");
        floorPrice = price_;
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
        require(price >= floorPrice, "Price is lower than floor price");
        require(supportedNfts[nftAddr], "Not supported NFT");
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
        uint256 protocolFee = (order.price * fee) / feeMax;

        paymentToken.transferFrom(msg.sender, order.owner, order.price - protocolFee);
        paymentToken.transferFrom(msg.sender, feeTo, protocolFee);
        IERC721(order.nftAddr).transferFrom(address(this), msg.sender, order.nftId);

        emit Buy(msg.sender, order.owner, order.nftAddr, order.nftId, order.price);
        _removeOrder(orderId);
    }

    function changePrice(uint256 orderId, uint256 price) public nonReentrant {
        require(price >= floorPrice, "Price is lower than floor price");
        Order storage order = orders[orderId];
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
            string memory tokenURI
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
            string memory tokenURI
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
            string memory tokenURI
        )
    {
        return getOrder(userOrderIds[user][index]);
    }
}
