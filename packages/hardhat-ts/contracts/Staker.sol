pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  //! users' balances
  mapping(address => uint256) public balances;

  //! threshold required for withdrawal
  uint256 public constant THRESHOLD = 1 ether;

  //! events
  event LogStake(address indexed staker, string message);

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit LogStake(msg.sender, 'You have just staked with us');
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  uint256 public deadline = block.timestamp + 72 hours;

  modifier checkEpoch(bool isOpenForWithdrawal) {
    uint256 remTime = timeLeft();

    if (isOpenForWithdrawal) {
      require(remTime >= 0, 'The deadline has already passed');
    } else {
      require(remTime == 0, 'There is still some time left');
    }
    _;
  }

  // checks whether external contract has received the stake
  // if it has, the function reverts
  modifier notCompleted() {
    bool complete = exampleExternalContract.completed();
    require(!complete, 'staking process already complete');
    _;
  }

  function execute() public checkEpoch(false) notCompleted {
    uint256 contractBalance = address(this).balance;

    require(contractBalance >= THRESHOLD, 'threshold not reached'); //can't sent money to other contract if threshold not met

    //? send to external contract
    // address exampleExternalContract = address(exampleExternalContract);
    (bool sent, ) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature('complete()'));
    console.log(unicode'\n\t 📤 sending to external contract...\n');
    require(sent, 'unable to send funds to external contract');
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public checkEpoch(true) {
    //find the user
    uint256 userBalance = balances[msg.sender];

    //check balance greater than 0
    require(userBalance > 0, "Can't withdraw when your balance is zero");

    //send money and set balance to zeror
    balances[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value: userBalance}('');
    require(sent, 'failed to sent user balance'); //what to do here incase the tx fails
  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
    // return remTime;
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    //stake received ether
    stake();
  }
}
