// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract StakeTest  {
  //  uint256 public deadline = 1000;
   
    struct Staker {
        address staker;
        uint256 stakeAmount;
        uint256 withdrawalAmount;
        uint256 totalBalances;
        bool isStaker;
    }

    struct Stake {
        address staker;
        address contractAddress;
        uint256 maxThreshold;
        uint256 deadline;
    }

   // Track Stakers by Address
     mapping(address => Staker) public stakers;

    //  List of Addresses for All Stakers
    //   To keep track of all stakers:
      address[] public stakersAddress;

    //   Track Stakes by Staker Address
    //   To map a staker's address to their stake:
      mapping(address => Stake) public stakes;

    //   Track Multiple Stakes Per Staker
    //   If each staker can have multiple stakes, you can use a nested mapping:

      mapping(address => mapping(uint256 => Stake)) public stakerStakes;

      mapping(address => uint256) public stakeCount;

      mapping(address => uint256) public balances;

    //   uint256 public constant threshold = 1 ether;
    
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    event StakeEvent(address funder, uint256 amount);

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    function StakeMoney(address funder, uint256 amount) public payable {
        require(balances[funder] >= amount,"The User Balance is Not sufficinet for staking activity");
        
        Staker storage staker = stakers[msg.sender];
       
        (bool success, ) = payable(address(this)).call{value : amount}("");
        require(success,"staking failed");
        staker.totalBalances -= amount;  
        staker.stakeAmount += amount;
        staker.isStaker= true;
        

        /////// now we have to reflect the above changes in the stake struct
        /////// make the stake count 
        uint256 count = stakeCount[msg.sender];
        ///// now track the staker stakes
        stakerStakes[msg.sender][count] = Stake(msg.sender, address(this), amount, block.timestamp + 7 days);
        stakeCount[msg.sender] += 1;

        stakersAddress.push(funder);


       
        emit StakeEvent(funder, amount);
        // 100 - 50 = 50  100 = 1 = 99 =
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
      function execute() public {
         require(block.timestamp > stakes[msg.sender].deadline,"the deadline have not passed");
         require(address(this).balance >= stakes[msg.sender].maxThreshold,"The Threshold have not passed");
         exampleExternalContract.complete{value : address(this).balance} ();
      }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
      function withdraw(address user, uint256 amount) public payable {
         ///// the stake contract balance must be below the maxThreshold
         require(address(this).balance < stakes[user].maxThreshold,"Threshold is not passed hence cannot withdraw");
         ////// amount must be postive to be withdraw
         require(amount > 0,"amount to withdraw must be nonzero");
         ////// amount to withdraw must be less than or equal to staked amount
         require(amount <= stakers[user].stakeAmount);
         
         Staker storage staker = stakers[user];
         (bool success,) = payable(user).call{value : staker.stakeAmount}("");
         require(success,"withdrawal failed");
         staker.totalBalances += staker.stakeAmount;
         staker.isStaker = false;

         ///// reflect the change to stake maxThreshold
         Stake storage stake = stakes[user];
         stake.maxThreshold -= staker.stakeAmount;

         /////(bool success,bytes32 rawDataReturned) = payable(msg.sender).call{value : address(this).balance}("");
         //////////revert(sucess,"withdrawal failed);
         //////////address(this).balance =  address(this).balance - amount;
        ////////// balances[user] =   balances[user] + amount;
      }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns(uint256) {
        require(block.timestamp >= stakes[msg.sender].deadline,"deadline is over");
       uint256 timeLeftOver =  stakes[msg.sender].deadline - block.timestamp;
       return timeLeftOver;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        StakeMoney(msg.sender, 20);
    }
}
