// SPDX-Licence-Identifier : MIT
pragma solidity ^0.8.18;
import {PriceConverter} from "./PriceConvertor.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public i_owner;
    uint256 public constant MIN_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "You Need To spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function Withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getVersion() public returns (uint256) {
        return s_priceFeed.version();
    }
}
