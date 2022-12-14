// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "accessRegistryContract.sol";

interface Iaccess{
    function addOwners(address _owner) external ;
    function renounce(address _renounceOwner) external;
    function transferSignature(address _from,address _to) external;
    function approve(uint _txId) external; 
    function execute(uint256 _txId) external;
    function revoke(uint256 _txId) external;
}


contract MultiSig is AccessRegistryContract {
    using SafeMath for uint256;
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool execute;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved; 
   
    fallback() external payable {
       require(msg.value > 0, "Amount must be greater than zero.");
       emit Deposit(msg.value, msg.sender);
    }

    receive() payable external{
        require(msg.value > 0,"pay some ether");
        emit Deposit(msg.value,msg.sender);
    }

    modifier Onlyowner(){
           require(isOwner[msg.sender],"not owner");
           _;      
    }
    modifier txexist(uint tx_id){
           require(tx_id>=0 && tx_id<transactions.length,"transaction doesnot exist");
           _;  
    }
    modifier txNotapproved(uint tx_id){
        require(!approved[tx_id][msg.sender],"transaction already approved by you");
        _;
    }
    modifier txNotexecuted(uint tx_id){
        require(!transactions[tx_id].execute,"transaction alreadry executed");
        _;
    }
    /*[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
       0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
       0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]
    
    */

    constructor(address[] memory _owners) AccessRegistryContract(_owners) {}

    /*
    [0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,10000000000000000000,0x00]
    */

    function addTransaction(address _to,uint256 _value,bytes memory _data)
        public Onlyowner{
            transactions.push(Transaction({
                                           to: _to,
                                           value: _value,
                                           data: _data,
                                           execute: false
                                    }));
            emit TxAdded(transactions.length-1);

    }
    //0x17F6AD8Ef982297579C203069C1DbfFE4348c372,1000000000000000000,0x00
    function approve(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId) txNotapproved(_txId){

        approved[_txId][msg.sender]=true;
        emit Approve(_txId,msg.sender);
    }

    function getNoofapproval(uint256 _txId) private view returns(uint256 count){
        for(uint256 i=0; i < owners.length ;i++){
            
            if( approved[_txId][msg.sender])  count++;

        }
    }

    function execute(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId){

        require(getNoofapproval(_txId)>=requiredOwners,"Not enough approval");
        Transaction storage transaction = transactions[_txId];
        transaction.execute = true;
        (bool success, )=transaction.to.call{value:transaction.value}(transaction.data);
        require(success,"transaction failed");
     
        emit Executed(_txId);

    }

    function revoke(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId){

        require(approved[_txId][msg.sender]==true,"already Not approved");
        approved[_txId][msg.sender]=false;

        emit Revoked(msg.sender,_txId);

    } 
    //[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]
   //[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,10000000000000000000,0x00]
}