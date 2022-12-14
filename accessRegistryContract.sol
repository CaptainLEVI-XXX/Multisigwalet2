// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AccessRegistryContract {
    using SafeMath for uint256;

    // events

    event ownerAddition(address indexed owner);
    event OwnersRequired(uint256 indexed requiredOwners);
    event ownerDiscarded(address indexed _renounceOwner);
    event TxAdded(uint256 indexed txId);
    event Deposit(uint256 indexed value,address indexed sender);
    event Approve(uint256 indexed txId,address indexed approval);
    event Executed(uint256 indexed txId);
    event Revoked(address indexed revoker,uint256 indexed txId);

    address public admin;
    address[] public owners;  
    mapping(address => bool) public  isOwner; 
    uint256 public requiredOwners;                   //required owners for approval of transactions

/*   
   minimum of three owners need to be the owners of wallet */

    constructor(address[] memory _owners){
        admin=msg.sender;
       
        require(_owners.length >= 3 ,"Minimum of three owners are required");
        /* Copying the neew owners to original owners array */
        
        for(uint256 i=0; i < _owners.length ; i++ ){
            owners.push(_owners[i]);
        }
        
        /* marking true of such address who are owners */
        
        for(uint256 i=0 ;i<_owners.length; i++){
            isOwner[_owners[i]]=true;
        }
       
       
        uint256 num = SafeMath.mul(owners.length,60);
        requiredOwners = SafeMath.div(num,100);

    }

    /*   Modifiers    */
    modifier NotUnknown(address caller){
        require(caller!=address(0),"Unknown address ");
        _;
    }

    modifier OnlyAdmin(){
        require(msg.sender==admin , " Not admin of the contract");
        _;
    }

    modifier OnlyOwner(address owner){
        require(isOwner[owner] , " Not Owner of the wallet");
        _;
    }

    modifier NotOwner(address notowner){
        require( !isOwner[notowner], " address is Owner of the wallet");
        _;
    }

    /*

    Public functions 
    
    */

    function addOwners(address _owner) public OnlyAdmin NotOwner(_owner) NotUnknown(msg.sender) {
    //  require(msg.sender!=address(0)," Unknown caller ");
        owners.push(_owner);
        isOwner[_owner]=true;
        //emiting the event for new owner addition
        emit ownerAddition(_owner);

        //calling the internal function to update the requiredowners for approval of any transaction
        ownersUpdate(owners);

    }

    function renounce(address _renounceOwner) public OnlyAdmin OnlyOwner(_renounceOwner) NotUnknown(msg.sender)
    NotUnknown(_renounceOwner){
        uint256 index;
        for(uint256 i=0; i < owners.length ; i++){
         
            if(owners[i]==_renounceOwner){
               index=i;
               break;                
            }
        }
        owners[index]=owners[owners.length-1];
        owners.pop();
        isOwner[_renounceOwner]=false;
         
        // emiting an event for discarding the owner 
        emit ownerDiscarded(_renounceOwner);
        ownersUpdate(owners);
    }

    function transferSignature(address _from,address _to) public OnlyOwner(_from) NotOwner(_to) OnlyAdmin
    NotUnknown(_from) NotUnknown(_to){

        for(uint256 i=0 ;i < owners.length ;i++){
            if( owners[i]==_from ){

                owners[i]=_to;
            }
        }
        isOwner[_from]=false;
        isOwner[_to]=true;

        emit ownerDiscarded(_from);
        emit ownerAddition(_to);
    }

    /* Internal functions */
    
    function ownersUpdate(address[] memory _owners) internal {

        uint num = SafeMath.mul(_owners.length,60);
        requiredOwners = SafeMath.div(num , 100);
        
        emit OwnersRequired(requiredOwners);

    } 

}

