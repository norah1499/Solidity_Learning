// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

//This smart contract enables escrow mechanism of payment for seller and buyer
//Idea is seller will intiate transfer of goods once the buyer has lock the funds in smart contract.
//So first buyer will lock the funds, then wait for goods to arrived, upon finding all well,
//He/she will confirm then the fund will be available to withdraw to seller
//Limitation of the following imlementation is the at a time buyer with particular seller can engage in only in single transaction
//This limitaion can be overcomed by tracking for each transcaton with uinique id through entire journey


contract Escrow{

    //This nested mapping will store the new payment requests from buyers
    //It mapps buyers to seller and payment amount
    mapping(address =>mapping(address => uint)) public newPayments;

    //This mapping will store the approved payments form newPayment confirming delivery of goods
    //Seller can only withdraw once the payment is listed in here against his/her address
    mapping(address => uint) public confirmedPayments;

    //This function will be called by buyer to add in new payment into the pool
    function addPayment(address _seller) public payable{

        //update the newPayments pool on the basis of recieved funds
        newPayments[msg.sender][_seller] = msg.value;

    }

    //This function will be called by buyer to confirm the delivery of the goods
    function confirmPayment(address _seller) public {

        //check if buyers had made added payment on the name of the seller in the first place
        //this will also ensure that only buyer can confirm the payment

        require(newPayments[msg.sender][_seller]>0,"No payment exist to confirm");

        //this is to remove the payment form newPayment list and then add it to confirmed list
        confirmedPayments[_seller] = newPayments[msg.sender][_seller];

        delete newPayments[msg.sender][_seller];

    } 


    //This function will be called by seller to recieve the confirm payments
    function withdraw() public{
        
        //to check if the caller has any due paymens
        require(confirmedPayments[msg.sender] > 0, "No pending payment on your address");

        //updating the balance of user
        delete confirmedPayments[msg.sender];
        
        //send the fund to the seller and update the confirmedPayments accordingly
       (bool sent, ) = msg.sender.call{value : confirmedPayments[msg.sender]}("");

        //checking if the transacton went succesfull or not
        require(sent,"Failed to send ether");

    }

}