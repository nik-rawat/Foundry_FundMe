// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { PriceConvertor } from "./PriceConvertor.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    mapping (address funder => uint amountFunded) private s_addressToAmountFunded;
    address [] private s_funders;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;


    constructor (address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function fund() public payable {
        require( msg.value.getConversionRate() >= MINIMUM_USD, "Didn't sent enough ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value.getConversionRate();
    }

    function withdraw() public onlyOwner {

        // require(msg.sender == i_owner, "Must be owner");
        for(uint funderIndex=0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

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

    /*
    View / Pure Functions (Getters)
     */

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }
}