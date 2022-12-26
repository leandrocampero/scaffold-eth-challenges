// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 60 seconds;
    bool public openForWithdraw = false;

    event Stake(address, uint256);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "Staking process is over"
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable notCompleted {
        require(timeLeft() > 0, "Deadline has expired");

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted {
        require(timeLeft() == 0, "Deadline has not yet expired");
        require(!openForWithdraw, "Staking process is over");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public payable notCompleted {
        require(openForWithdraw, "Not open for withdraw");
        require(balances[msg.sender] > 0, "This wallet has not staked funds");

        (bool sent, bytes memory data) = msg.sender.call{
            value: balances[msg.sender]
        }("");

        require(sent, "Failed to withdraw ethers");
        balances[msg.sender] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 left) {
        if (block.timestamp >= deadline) {
            left = 0;
        } else {
            left = deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
