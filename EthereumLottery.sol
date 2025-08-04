// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery3D {
    // 管理员地址
    address public owner;

    // 单注彩票价格
    uint256 public ticketPrice = 0.001 ether;

    constructor() {
        owner = msg.sender;
    }

    // 限制只有管理员能调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // 单个购买彩票信息：用户地址 + 购买数量
    struct PurchaseInfo {
        address buyer;
        uint256 amount;
    }

    // 每期开奖信息
    struct RoundInfo {
        bool isOpen;           // 是否开放购买
        uint256 deadline;      // 截止时间（时间戳）
        bool isDrawn;          // 是否已开奖
        uint256 winningNumber; // 开奖号码
    }

    // 记录：期号 => 彩票号码 => 用户购买列表
    mapping(uint256 => mapping(uint256 => PurchaseInfo[])) public ticketRecords;

    // 记录：期号 => 开奖信息
    mapping(uint256 => RoundInfo) public rounds;

    // 事件：购买彩票
    event TicketBought(uint256 round, address indexed buyer, uint256 number, uint256 amount);

    // 事件：新一期开启
    event RoundOpened(uint256 round, uint256 deadline);

    // 事件：开奖
    event RoundDrawn(uint256 round, uint256 winningNumber);

    // 事件：奖金发放
    event PrizeDistributed(address indexed winner, uint256 round, uint256 amount);

    // 管理员开启新一期彩票
    function openRound(uint256 round, uint256 duration) external onlyOwner {
        require(!rounds[round].isOpen, "Round already open");
        require(duration > 0, "Duration must be > 0");

        // 初始化新一期彩票信息
        rounds[round] = RoundInfo({
            isOpen: true,
            deadline: block.timestamp + duration,
            isDrawn: false,
            winningNumber: 9999 // 初始值，未开奖
        });

        emit RoundOpened(round, rounds[round].deadline);
    }

    // 用户购买彩票
    function buyTicket(uint256 round, uint256 number, uint256 amount) external payable {
        require(rounds[round].isOpen, "Round not open");
        require(!rounds[round].isDrawn, "Round already drawn");
        require(block.timestamp <= rounds[round].deadline, "Round closed");
        require(number <= 999, "Invalid number");
        require(amount > 0, "Amount must be > 0");
        require(msg.value == ticketPrice * amount, "Incorrect ETH sent");

        // 记录购买信息
        ticketRecords[round][number].push(PurchaseInfo({
            buyer: msg.sender,
            amount: amount
        }));

        emit TicketBought(round, msg.sender, number, amount);
    }

    // 管理员开奖并发放奖金
    function draw(uint256 round, uint256 winningNumber) external onlyOwner {
        require(rounds[round].isOpen, "Round not open");
        require(!rounds[round].isDrawn, "Already drawn");
        require(block.timestamp > rounds[round].deadline, "Round not ended");
        require(winningNumber <= 999, "Invalid number");

        // 设置开奖结果
        rounds[round].isDrawn = true;
        rounds[round].isOpen = false;
        rounds[round].winningNumber = winningNumber;

        emit RoundDrawn(round, winningNumber);

        // 获取中奖用户列表
        PurchaseInfo[] storage winners = ticketRecords[round][winningNumber];
        uint256 prizePerTicket = 1 ether; // 每注奖金（可以改为动态计算）

        // 发放奖金
        for (uint i = 0; i < winners.length; i++) {
            uint256 totalPrize = winners[i].amount * prizePerTicket;
            payable(winners[i].buyer).transfer(totalPrize);
            emit PrizeDistributed(winners[i].buyer, round, totalPrize);
        }
    }
}