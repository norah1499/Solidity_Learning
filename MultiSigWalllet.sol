// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

//This smart contract will take list of owners and the no of signatures needed to confirm the
//the excution of the transcation, which were submitted by one of them only
//Idea is, say in we have 3 onwers and atleast 2 signature are required to execute any transcation.
//One owner will submit the transcation then it will have to wait until atleast one another owner
//confirms to allow the spending
    
contract MultisigWallet{

    //events about key activities
    event Deposit(address indexed owner, uint value, uint balance);
    event SubmitTransaction(address indexed owner,uint indexed TransactionIndex,address indexed _to, uint _amount,bytes _data);
    event ConfirmTransaction(address indexed owner,uint indexed TransactionIndex, uint confirmationCount);
    event ExecuteTransctiion(address indexed owner,uint indexed TransactionIndex);


    //key variables, set inside constructors
    address[] public owners;
    uint8 public confirmationNeeded;
    mapping(address => bool) public isOwner;

    //Structure to store the meta data related transaction proposed
    struct Transaction{
        address _to;
        uint _amount;
        bytes _data;
        uint _noofConfirmation;
        bool _isExecuted;
    }

    //All the transcation will be stored in this array
    Transaction[] public transactions;

    //to store whether owner has already confirmed the transaction or not
    mapping(uint=>mapping(address=>bool)) public isConfirmed;

    //only onwer can access certain fucntion
    modifier OnlyOwner(){
        require(isOwner[msg.sender],"Not owner");
        _;
    }

    //proceed only if it the transaction is not confirm yet
    modifier notConfimedyet(uint _txId,address _owner){
        require(isConfirmed[_txId][_owner]==false,"Already confirmed !");
        _;
    }

    //proceed if transaction is not executed yet
    modifier notExecutedyet(uint _txId){
        require(transactions[_txId]._isExecuted==false,"Already executed !");
        _;
    }


    constructor(address[] memory _owners, uint _confirmationNeeded) {

        require(_owners.length > 0, "Please provide owners");

        for(uint i=0; i<_owners.length; i++){

            address owner = _owners[i]; //placeholder

            require(owner!=address(0),"User does not exist");
            require(!isOwner[owner],"Not unique owner");

            //adding owners to mapping
            isOwner[_owners[i]] = true;

            //updating array with owners
            owners.push(_owners[i]);
        }

        require(_confirmationNeeded>0 && _confirmationNeeded<_owners.length, "Invalid number of confirmation");
        
        //setting the confirmation count needed to execute the transaction
        confirmationNeeded = uint8(_confirmationNeeded);

    }

    //function to deposit money to the contract, msg.value is the money is sent
    function deposit() public OnlyOwner payable{

        emit Deposit(msg.sender, msg.value,address(this).balance);

    }
    
    //function to submit the transaction
    function submitTransaction(address _to, uint _amount,bytes calldata _data) public OnlyOwner{

        //check if the smart contract has enough balance
        require(_amount<address(this).balance,"Not enough balance");

        //indexing the transcation for neccesary tracking
        uint _txId = transactions.length;
        
        //create new transcation with value sentin argument and noOfconfirmation to 1 and IsExecuted to false
        transactions.push(Transaction(_to,_amount,_data,0,false));

        //emit the event announcing submission of transaction 
        emit SubmitTransaction(msg.sender,_txId,_to,_amount,_data);

    }

    //function to confirmed the submitted transcation
    function confirmTransaction(uint _txId) public OnlyOwner notExecutedyet(_txId) notConfimedyet(_txId, msg.sender) {
        
        //storage pointer pointing our indexed transaction
        Transaction storage transaction= transactions[_txId];

        //Update the sender ("Owner") in hasconfirmed mapping 
        isConfirmed[_txId][msg.sender] = true;

        //Increase the confirmation count
        transaction._noofConfirmation+=1;

        emit ConfirmTransaction(msg.sender,_txId,transaction._noofConfirmation);

    }

    //function to execute the transaction
    function executeTransaction(uint _txId) public notExecutedyet(_txId) {

        //storage pointer pointing our indexed transaction
        Transaction storage transaction= transactions[_txId];

        //Checks if the enough confirmation are there
        require(transaction._noofConfirmation >= confirmationNeeded,"Not Enough confirmation !");

        //Updating the execution status on transaction
        transaction._isExecuted = true;

        //executing the transaction finally
        (bool success, ) = transaction._to.call{value:transaction._amount}(transaction._data);

        require(success, "Transaction failed !");

        emit ExecuteTransctiion(msg.sender,_txId);

    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint _txId) public view returns( address _to,uint _amount,bytes memory _data,uint _noofConfirmation,bool _isExecuted) {

        Transaction storage transaction= transactions[_txId];

        return (transaction._to,transaction._amount,transaction._data,transaction._noofConfirmation,transaction._isExecuted);

    }
     
    function getTranscationCount() public view returns(uint numberofTransactions){

        return transactions.length;

    }

}