pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
  uint constant public minParticipants = 2;
  uint constant public maxParticipants = 10;
  address payable[] public participants;
  address payable public winner;

  /**
   * @dev user can participate the lottery through calling this
   * function
   */
  function participate() external payable {
    require(msg.value >= 0.001 ether, "not enough ether");
    require(
      participants.length < 10,
      "participants is enough for this round"
    );
    participants.push(payable(msg.sender));
  }
  
  /**
   * @dev decide winner and transfer contract's balance to the
   * winner
   */
  function execute() external onlyOwner {
    require(
      participants.length >= minParticipants,
      "not enough participants"
    );
    uint randomNumber = uint(keccak256(abi.encodePacked(block.difficulty)));
    uint winnerIndex = randomNumber % participants.length;
    participants[winnerIndex].transfer(address(this).balance);
    delete participants;
  }

  /**
   * @dev return number of participants
   */
  function participantsNumber() external view returns (uint) {
    return participants.length;
  }
}