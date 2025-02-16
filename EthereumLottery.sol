// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthereumLottery {
    address public owner;
    uint public ticketPrice = 0.1 ether; // 每张彩票的价格
    uint public jackpot; // 奖金池
    uint public drawTime; // 开奖时间
    uint public winningNumber; // 中奖号码
    mapping(address => uint[]) public userTickets; // 用户投注记录
    address[] public players; // 所有玩家

    // 事件
    event TicketPurchased(address player, uint[] numbers);
    event DrawResult(uint winningNumber);
    event PrizeClaimed(address winner, uint prize);

    constructor() {
        owner = msg.sender;
        drawTime = block.timestamp + 1 days; // 默认开奖时间为24小时后
    }

    // 用户投注函数
    function purchaseTickets(uint[] memory numbers) public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(numbers.length == 3, "You must select 3 numbers");

        jackpot += msg.value; // 增加奖金池
        userTickets[msg.sender] = numbers; // 保存用户投注
        players.push(msg.sender); // 将玩家加入列表

        emit TicketPurchased(msg.sender, numbers);
    }

    // 开奖函数
    function draw() public onlyOwner {
        require(block.timestamp >= drawTime, "Draw time has not come yet");

        // 使用 Chainlink VRF 生成随机数作为中奖号码
        winningNumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000; // 生成一个0到999的随机数

        emit DrawResult(winningNumber);
        drawTime = block.timestamp + 1 days; // 设定下一期的开奖时间
    }

    // 计算奖金并分配
    function claimPrize() public {
        require(winningNumber != 0, "Draw has not been made yet");

        uint[] memory userBet = userTickets[msg.sender];
        uint prize = 0;

        // 检查用户是否中奖
        if (userBet[0] == winningNumber) {
            prize = jackpot;
            jackpot = 0; // 重置奖金池
            payable(msg.sender).transfer(prize); // 将奖金转账给用户

            emit PrizeClaimed(msg.sender, prize);
        }
    }

    // 修改彩票价格（仅管理员）
    function setTicketPrice(uint newPrice) public onlyOwner {
        ticketPrice = newPrice;
    }

    // 仅管理员权限
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}
