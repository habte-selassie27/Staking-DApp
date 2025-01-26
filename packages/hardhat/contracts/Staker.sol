// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import console for debugging purposes
import "hardhat/console.sol";

interface IExampleExternalContract {
    function complete() external payable;
}

contract Staker {
    // State variables
    mapping(address => uint256) public balances; // Tracks individual total balances
    mapping(address => uint256) public stakedBalances; /// tracks individual staked balances
    uint256 public constant threshold = 1 ether; // Threshold for staking success
    uint256 public deadline = block.timestamp + 72 hours; // Deadline for staking
    bool public openForWithdraw; // Indicates if funds can be withdrawn
    IExampleExternalContract public exampleExternalContract; // External contract reference

    // Events
    event Stake(address indexed staker, uint256 amount);
    event Withdraw(address indexed staker, uint256 amount);
    event Execute(address indexed executor, uint256 contractBalance, bool success);

    // Modifier to ensure the external contract is not yet completed
    modifier notCompleted() {
        require(!openForWithdraw, "Staking already completed or withdrawn");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = IExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 72 hours; // Set initial deadline
    }

   

   function stake() public payable {
      require(msg.value > 0, "Cannot stake 0 tokens");
     //// require(balances[user] >= msg.value, "Insufficient balance");
      
      //// Deduct from user's available balance
       balances[msg.sender] += msg.value;
      
       // Update staked balance
       stakedBalances[msg.sender] += msg.value;
       emit Stake(msg.sender,msg.value);
  }

    // Function to check remaining time
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Function to execute staking logic after the deadline
    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Staking period is still active");

        uint256 contractBalance = address(this).balance;

        if (contractBalance >= threshold) {
            exampleExternalContract.complete{value: contractBalance}();
            emit Execute(msg.sender, contractBalance, true);
        } else {
            openForWithdraw = true; // Enable withdrawals
            emit Execute(msg.sender, contractBalance, false);
        }
    }

    function withdraw() public {
      uint256 stakedAmount = stakedBalances[msg.sender];
      require(stakedAmount > 0, "Cannot withdraw from non staker user");
    //require(stakedBalances[msg.sender] < threshold, "");
    
    // Decrease the user's staked balance
     stakedAmount = 0;

    // Add the withdrawn amount back to the user's total balance
    balances[msg.sender] += stakedAmount;

    // Transfer  back to the user
    (bool success, ) = payable(msg.sender).call{value: stakedAmount}("");
    require(success, "Failed to send Ether");
    
     emit Withdraw(msg.sender, stakedAmount);
        
  }

    // Receive function to handle direct ETH transfers
    receive() external payable {
        balances[msg.sender] += msg.value;
      
    }

    // Fallback function (optional, for additional flexibility)
    fallback() external payable {
         balances[msg.sender] += msg.value;
        stake(); // Automatically call the stake function
    }
}
