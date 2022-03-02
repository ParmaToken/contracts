// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/*
    @Parma Token
    - Website: https://parmatoken.com/
    - Telegram: https://t.me/ParmaToken

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@   @@@@@@@@   @@@@@       @@@@@   @@@@@@@@   @@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@  @@  ,,,,,  @@  @@@@@@@@@@@@@@@  @@  ,,,,,  @@  @@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@  @@ ,,,,,,,,, @@@%             ,@@@ ,,,,,,,,, @@  @@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@  @ ,,,,,,,,,,, @@@@@ @@@@@@@ @@@@@@,,,,,,,,,,, @  @@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@  @ ,,,,,,,,,,, @@(             *@@ ,,,,,,,,,,, @  @@@@@@@@@@@@@@
    @@@@@@@@@@@@@   @@@ ,,,,,,,,@@                     @@,,,,,,,, @@@   @@@@@@@@@@@@
    @@@@@@@@@@@  &@@   @@ ,,,, @                         @ ,,,, @@   @@#  @@@@@@@@@@
    @@@@@@@@@@  @@       @@@  @                           @  @@@       @@  @@@@@@@@@
    @@@@@@@@  @@             @                             @             @@  @@@@@@@
    @@@@@@@  @@             @                               @             @@  @@@@@@
    @@@@@@  @@            @@       @@@            @@@@       @@            @@  @@@@@
    @@@@@@ @@            @@       @@@@@           @@@@        @@            @@ @@@@@
    @@@@@  @@            @          @@             @@          @            @@  @@@@
    @@@@@  @             @@                                   @@             @  @@@@
    @@@@@ %@               @      &@@@  @@,,,,,@@ @@@@       @               @, @@@@
    @@@@@ .@        #@@@@@@@ @@   @@@@   @*,,,@@   @@@%   @@/@@@@@@@         @  @@@@
    @@@@@  @                @@@@@@@@              @@.....@@@                 @  @@@@
    @@@@@  @@         @@@             @@,    @@@......,,@.....@@@@@         @@  @@@@
    @@@@@@  @,                           @@......................@@        &@  @@@@@
    @@@@@@@  @                      @@@.............................@      @  @@@@@@
    @@@@@@@@  @.                @@...,@*..............................@  @@  @@@@@@@
    @@@@@@@@@  @@             @@.......................@@@@@@,,,,,,,,,,@@@  @@@@@@@@
    @@@@@@@@@@   @@     @@.......&@@@@@(,,,,,,,,,,,,,,,,,,,,,,,@*@,,,,,@   @@@@@@@@@
    @@@@@@@@@@@@  .@@  @,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**%,,@@   @@@@@@@@@@
    @@@@@@@@@@@@@@   @@  @@,,,,@**,,,,,,,,,,,,,,,,,,,,@******@,,,,,,@  @@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@   @@@@,,,,,,,,,,,@**@,,,,,,,,,,,*********,,,,,,@@   @@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@  @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,@****@,,,,,,,,,@  @@@@@@@@@@
    @@@@@@@@@@@@@@@@@@  @@,,,,,,,,,,,,,,,,,,,,,,,,,,@*,,,,,,,,,,,,(,,,,@  @@@@@@@@@@
    @@@@@@@@@@@@@@@@@@  @,,,,@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@  @@@@@@@@@@
    @@@@@@@@@@@@@@@@@@  @,,,,,,,,,,,,,,,@@    @&,,,,,,,,@@@@@@@@@@@      @@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@ @@,,,,,,,,@@@@@@  @@@@               @@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@              *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

contract ParmaNodes is Ownable {
    using SafeMath for uint256;

    uint256 public nodesLimit;
    uint256 public nodeCost;
    uint256 public claimFee;
    address private lpAddress;

    bool public nodesPaused = false;
    uint256 public totalNodes;

    IERC20 public parmaToken = IERC20(0x1A2933fbA0c6e959c9A2D2c933f3f8AD4aa9f06e);
    Reward public dailyReward;
    
    struct User {
        address addr;
        uint256 created;
        uint256 lastCreated;
    }

    struct Node {
        uint256 id;
        string name;
        string description;
        uint256 created;
        uint256 timestamp;
        uint256 reward;
        uint256 claimed;
    }

    struct Reward {
        uint256 reward;
        uint256 updated;
    }

    mapping(address => mapping(uint256 => Node)) public _nodes;
    mapping(address => User) public _user;

    constructor() {
        nodesLimit = 100;
        nodeCost = uint256(1000000).mul(1e18);
        dailyReward = Reward({reward: uint256(33333).mul(1e18), updated: block.timestamp});
        claimFee = 5;
        lpAddress = address(0x8cda2065f49be9A1DEd69B7c7D60Db8759D22322);
    }

    modifier nodeExists(address creator, uint256 nodeId) {
        require(_nodes[creator][nodeId].id > 0, "This node does not exists.");
        _;
    }

    function nodeClaimed(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (uint256) {
        return _nodes[creator][nodeId].claimed;
    }

    function userNode(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (Node memory) {
        return _nodes[creator][nodeId];
    }

    function rewardCheck(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (bool) {
        return _nodes[creator][nodeId].reward == dailyReward.reward;
    }
    
    function nodeEarned(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (uint256) {
        Node memory node = _nodes[creator][nodeId];
        uint256 nodeStart = node.timestamp;
        uint256 reward = node.reward;

        uint256 nodeAge = block.timestamp / 1 seconds - nodeStart / 1 seconds;

        if (dailyReward.reward < reward) {
            uint256 updatedTime = block.timestamp / 1 seconds - dailyReward.updated / 1 seconds;
            nodeAge -= updatedTime;
        }

        uint256 rewardPerSec = reward.div(86400);
        uint256 earnedPerSec = rewardPerSec.mul(nodeAge);

        return earnedPerSec;
    }

    function createNode(string memory name, string memory desc, uint256 amount) external {
        require(!nodesPaused, "Nodes are currently paused.");

        if (_user[msg.sender].addr != msg.sender) {
            _user[msg.sender] = User({
                addr: msg.sender,
                created: 0,
                lastCreated: 0
            });
        }

        uint256 totalCost;
        for (uint256 i = 0; i < amount; i++) {
            require(_nodes[msg.sender][nodesLimit].id == 0, "You cannot create any more nodes.");

            uint256 nodeId = (_user[msg.sender].lastCreated).add(1);
            _nodes[msg.sender][nodeId] = Node({
                id: nodeId,
                name: name,
                description: desc,
                created: block.timestamp,
                timestamp: block.timestamp,
                reward: dailyReward.reward,
                claimed: 0
            });

            totalCost += nodeCost;
            totalNodes += 1;
            _user[msg.sender].created += 1;
            _user[msg.sender].lastCreated = nodeId;
        }

        require(parmaToken.balanceOf(msg.sender) > totalCost, "Insufficient Funds in wallet");

        uint256 lpFee = totalCost.mul(10).div(100);

        parmaToken.transferFrom(msg.sender, address(this), totalCost.sub(lpFee));
        parmaToken.transferFrom(msg.sender, lpAddress, lpFee);
    }

    function claimEarnings(uint256 nodeId) external nodeExists(msg.sender, nodeId) {
        require(!nodesPaused, "Nodes are currently paused.");

        uint256 reward = nodeEarned(msg.sender, nodeId);

        uint256 feeAmt = reward.mul(claimFee).div(100);
        reward -= feeAmt;

        parmaToken.transfer(msg.sender, reward);
        parmaToken.transfer(lpAddress, feeAmt);

        _nodes[msg.sender][nodeId].claimed += reward;
        _nodes[msg.sender][nodeId].reward = dailyReward.reward;
        _nodes[msg.sender][nodeId].timestamp = block.timestamp;
    }

    function claimAllEarnings() external {
        require(!nodesPaused, "Nodes are currently paused.");

        uint256 totalClaim;
        for (uint256 i = 1; i < nodesLimit+1; i++) {
            if (_nodes[msg.sender][i].id == 0) break;

            uint256 reward = nodeEarned(msg.sender, i);

            _nodes[msg.sender][i].claimed += reward;
            _nodes[msg.sender][i].reward = dailyReward.reward;
            _nodes[msg.sender][i].timestamp = block.timestamp;

            totalClaim += reward;
        }

        uint256 feeAmt = totalClaim.mul(claimFee).div(100);
        totalClaim -= feeAmt;

        parmaToken.transfer(msg.sender, totalClaim);
        parmaToken.transfer(lpAddress, feeAmt);
    }

    function setNodesLimit(uint256 limit) external onlyOwner {
        nodesLimit = limit;
    }

    function updateDailyReward(uint256 reward) external onlyOwner {
        dailyReward.reward = reward.mul(1e18);
        dailyReward.updated = block.timestamp;
    }

    function updateNodeCost(uint256 cost) external onlyOwner {
        nodeCost = cost.mul(1e18);
    }

    function setClaimFee(uint256 fee) external onlyOwner {
        claimFee = fee;
    }

    function setNodesPaused(bool onoff) external onlyOwner {
        nodesPaused = onoff;
    }

    function setLPAddress(address addr) external onlyOwner {
        lpAddress = addr;
    }
}