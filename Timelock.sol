// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

//This contract locks users fund for duration of week
contract TimeLock{

    //Mapping to store the amount of money deposited by user
    mapping (address => uint) public deposits;

    //Mappig to keep track of the time left until the user can withdraw
    mapping (address => uint) public VestingTime;

    //Function to deposit money
    function deposit() public payable {
        
        //update the balance and lockIn time of the depositer
        deposits[msg.sender] = msg.value;
        VestingTime[msg.sender] = block.timestamp + 1 weeks;

        //transfer money to contracts address
        //payable(msg.sender).transfer(msg.value);
       
    }

    //Function to withdraw deposited money
    function withdraw() public {

        //check if user hasdeposoted any money
        require(deposits[msg.sender]>0,"user does not exist");

        //check if the lock in time is over or not  
        require(VestingTime[msg.sender] < block.timestamp, "Vesting period is not over yet");
        
        //updating the balance of user and vesting time
        delete deposits[msg.senderl;
        delete VestingTIime[msg.sender];
        
        //sending money from contracts address to user
        (bool sent, ) = msg.sender.call{value : deposits[msg.sender]}("");

        //checking if the transacton went succesfull or not
        require(sent,"Failed to send ether");        
    }

}
