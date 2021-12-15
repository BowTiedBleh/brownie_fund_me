// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// importing from NPM/Github. Same as copying and pasting in the interface code directly
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// import SafeMath to avoid wrapping. SafeMathChainlink is basically the same as Openzeppelin SafeMath
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    // keep track of who sent funding
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // want this function to accept some type of payment (i.e. be a payable function)
    function fund() public payable {
        // Set minimum amount funded to $50 (in Wei)
        uint256 minimumUSD = 50 * 10**8;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        // what is the ETH -> USD conversion rate? => data.chain.link/eth-usd
    }

    function getVersion() public view returns (uint256) {
        // this says we have a contract at the defined address (0x8A753...) that has the functions defined in the interface (imported above)
        // address is the ETH to USD contract on the Rinkeby Testnet, found here: https://docs.chain.link/docs/ethereum-addresses/
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //return blanks separated by commas to avoid unused variable warning & for cleaner code
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // have to divide to account for decimals
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //only want the contract admin/owner
        //require msg.sender = owner
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
