// Created by EighthLayer 
// More contracts at https://github.com/EighthLayer/FiftyFiftyContracts
pragma solidity >= 0.5.0 < 0.6.0;

import "github.com/provable-things/ethereum-api/provableAPI.sol";

contract PointOneEthFiftyFifty is usingProvable
{
   
    address payable[] public users; // array of users who sent .5 eth to the contract
    bool public activeContract = true; 
    
    uint256 constant MAX_INT_FROM_BYTE = 3;
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

    event LogWinner(address payable);
    event generatedRandomNumber(uint256 randomNumber);
    event errorLog(string desc);
   
    function deposit() payable public {
        require(msg.value == 500000000000000000); // only accept .5 eth as payment
        require(activeContract = true); // check to make sure the contract hasn't already been used
        require(address(this).balance <= 1000000000000000000); // stop people from sending multiple deposits in the same block
        users.push(msg.sender); // add the address that sent it to our users array
       
        if(users.length == 2 && address(this).balance == 1000000000000000000){ // if two people have entered the bet
            activeContract = false; // stop letting people send eth to the contract
            provable_setProof(proofType_Ledger);
            getProvableRandom(); // calculate the winner
        }
       
       
    }
   
    function getBalance() public view returns (uint256){ // checks current contract balance
        return address(this).balance;
    }
   
    function chooseWinner(address payable[] memory userArray, uint winningNumber) internal { // code to determine the winner
       
        if(winningNumber == 0){ // if the first user wins
            userArray[0].transfer(address(this).balance); // send the entire amount (1 eth)
            emit LogWinner(userArray[0]);
        }else if(winningNumber == 1){  // if the second user wins
            userArray[1].transfer(address(this).balance); // send the entire amount (1 eth)
            emit LogWinner(userArray[1]);
        }
         
        delete users; // clear the array for the next two users
        activeContract = true; // turn the contract back on for deposits
    }
    
    
    // oraclize 
    
     function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress()); // prove call is from provable
        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // proof has failed, cancel contract and return funds
           emit errorLog("Oracle Proof Failed, Returning Funds...");
           users[0].transfer(address(this).balance / 2);
           users[1].transfer(address(this).balance);
           delete users;
           
        } else {
            // math to choose turn hex into 0 or 1
            uint256 ceiling = (MAX_INT_FROM_BYTE ** NUM_RANDOM_BYTES_REQUESTED) - 1;
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % ceiling;
            if(randomNumber == 0 || randomNumber == 1){
                chooseWinner(users,randomNumber);
            }else{
                // number returned by proof is not a possiblity, cancel contract and return funds
                emit errorLog("Random Number is out of bounds, Returning Funds...");
                users[0].transfer(address(this).balance / 2);
                users[1].transfer(address(this).balance);
                delete users;
            }
            emit generatedRandomNumber(randomNumber);
        }
    }
    
    function getProvableRandom() internal{
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 175000; // can change for faster or slower confirmations? DEFAULT: 200000
        provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
    }
}
