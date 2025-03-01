// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { PriceConvertor } from "./PriceConvertor.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    AggregatorV3Interface internal dataFeed;

    uint256 public constant MINIMUM_USD = 5e18;

    address [] public funders;
    mapping (address funder => uint amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor () {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        i_owner = msg.sender;
    }

    function getVersion() public view returns (uint256) {
        return dataFeed.version();
    }

    function fund() public payable {
        require( msg.value.getConversionRate() >= MINIMUM_USD, "Didn't sent enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value.getConversionRate();
    }

    function withdraw() public onlyOwner {

        // require(msg.sender == i_owner, "Must be owner");
        for(uint funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // //transfer
        // payable (msg.sender).transfer( address(this).balance );

        // //send
        // bool sendSuccess = payable (msg.sender).send( address(this).balance );
        // require(sendSuccess, "Send Failed");

        //call
        (bool callSuccess, ) = payable (msg.sender).call{ value: address(this).balance }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!");
        if (msg.sender == i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }


}