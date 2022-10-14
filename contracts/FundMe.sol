// SPDX-License-Identifier: MIT

// This contract uses the Goerli testnet
pragma solidity >=0.6.6 <0.9.0;

//AggregatorV3Interface.sol Get a price feed for ETH => USD
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//Check & avoid overflow (a uint256 to not have a number with more than 256 bits)
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe{
    using SafeMathChainlink for uint256; //Avoid overflow for all uint256

    mapping(address => uint256) public addressToAmount;
    address[] public funders; //Add the address of a funder in an array
    address owner; //Address of the owner of the contract
    address goerliAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; //Goerli Testnet address (ETH/USD)

    constructor() public{
        owner = msg.sender; //The sender of the msg will be the owner. The deployer of the contract
    }

    //payable: Function to pay for things.
    //It is the 'VALUE' input in the 'DEPLOY & RUN TRANSACTIONS' tab in Remix
    function fund() public payable {
        //Set a minimum value to send
        uint256 minUSD = 50 * 10**18; //50$ * 10^18 to get the value in wei
        //If the sended value is less than the minUSD then stop excecution.
        //'require' reverts the transaction & gives back the money & the unspended gas to the sender
        require(getConversion(msg.value) >= minUSD, "You must spend more ETH!");
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(goerliAddress);
        return priceFeed.version();
    }

    //Get eth price 
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(goerliAddress);
        //This is a tuple (A list with objects of different type)
        //',' means something will be returned there but ignore it
       (,int256 answer,,,) = priceFeed.latestRoundData();
        //The 'answer' is returned in gwei(8 decimals). We want
        //wei: 18 decimals so we have to do 'answer * (10^10)'
        return uint256(answer * (10^10)); 
    }

    //Convert whatever value they send e.g. 15gwei to USD 
    function getConversion(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ((ethPrice*ethAmount) / (10**18)); //Have to divide with 10^18 which is 1 ETH in WEI
        //The answer is also in 18 decimals even though we divided with 10^18
        //So if we get something with <18 numbers we add 0 at the front
        //E.G. answer = 2533896352720. So the real answer is 0.000002533896352720. This is 1 GWEI in USD
        //If we multiply this with 10^10 we get ETH -> USD. ETH was 2,533.896352720 at the time of this programm
        return ethAmountInUSD;
    }

    //Modifier so that only the owner of the contract can withdraw money
    modifier onlyOwner {
        require(msg.sender == owner);
        _; //After finding the '_' leave the modifier & run the rest of the code
    }

    //Withdraw all the money this contract holds from funding
    //Add the modifier to be checked
    function withdraw() payable onlyOwner public{
        //transfer(): Send ETH from 1 address to another. 
        //e.g. Send to msg.sender
        //Inside the () we choose how much money will be transferred
        //e.g. All the money that've been funded
        //this: Refers to the contract we are currently in
        //address(this): The address of the contract we are currently in
        //e.g. give all the balance(money) of the contract address to the msg.sender
        msg.sender.transfer(address(this).balance);
        for(uint256 i=0; i<funders.length; i++){
            address funder = funders[i];
            addressToAmount[funder] = 0; //Empty the balance of each address
        }
        funders = new address[](0); //Reset our funders array
    }
}