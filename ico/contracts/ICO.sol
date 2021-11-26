// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract ICO is Ownable {
  uint constant public TOKENS_PER_ETH = 1000;
  uint constant public MAX_INVESTMENT = 10 ether;
  uint constant public MIN_INVESTMENT = 0.001 ether;
  uint constant public HARDCAP = 100 ether;

  address payable recipient;
  uint public startBlock;
  uint public endBlock;
  uint public fundraised; // tracking fundraised fund
  MyToken public myToken;

  event Invest(address indexed from, uint amount);

  constructor(
    address _recipient,
    uint _startBlock,
    uint _endBlock,
    uint _tradeableAfterBlock
  ) {
    recipient = payable(_recipient);
    startBlock = _startBlock;
    endBlock = _endBlock;
    myToken = new MyToken(_tradeableAfterBlock);
  }

  /**
   * @dev Throws if block.number not in the range of start & end block
   */
  modifier notInTime() {
    require(
      block.number >= startBlock,
      "ICO not start yet"
    );
    require(
      block.number <= endBlock,
      "ICO ended"
    );
    _;
  }

  /**
   * @dev User can participate the ICO through this function
   */
  function invest() public payable notInTime {
    require(
      msg.value >= MIN_INVESTMENT,
      "Not enough investment"
    );
    require(
      msg.value <= MAX_INVESTMENT,
      "Exceed maximum value of investment"
    );
    fundraised += msg.value;
    require(
      fundraised <= HARDCAP,
      "Hardcap exceeded"
    );
    recipient.transfer(msg.value);
    uint tokenReturn = msg.value * TOKENS_PER_ETH;
    myToken.mint(msg.sender, tokenReturn);
    emit Invest(msg.sender, tokenReturn);
  }

  /**
   * @dev Update blocks
   */
  function setBlocks(uint _startBlock, uint _endBlock) public onlyOwner {
    startBlock = _startBlock;
    endBlock = _endBlock;
  }
}