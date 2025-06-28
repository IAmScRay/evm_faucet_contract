// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Faucet {

    address public owner;
    uint256 public distributionAmount = 0 ether;

    bool public paused = false;

    event Distribution(address receiver);

    event Paused();
    event Unpaused();

    event DistributionAmountChanged(uint256 newAmount);

    event Withdrawal(uint256 amount, address receiver);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(uint256 _amount) {
        distributionAmount = _amount;
        emit DistributionAmountChanged(_amount);

        owner = msg.sender;
    }

    function setDistributionAmount(uint256 _amount) external onlyOwner {
        distributionAmount = _amount;
        emit DistributionAmountChanged(_amount);
    }

    function pause() external onlyOwner {
        require(!paused, "Already paused");

        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        require(paused, "Already unpaused");

        paused = false;
        emit Unpaused();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough ETH");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdraw failed");

        emit Withdrawal(balance, owner);
    }

    function distribute(address[] calldata recipients) external onlyOwner notPaused {
        uint256 totalRequired = recipients.length * distributionAmount;
        require(address(this).balance >= totalRequired, "Not enough ETH");

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(distributionAmount);
            emit Distribution(recipients[i]);
        }
    }

    receive() external payable {}

    fallback() external payable {
        revert("Not supported");
    }

}