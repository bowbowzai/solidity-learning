// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
  uint tradeAfterBlock;

  constructor(uint _tradeAfterBlock) ERC20("My Token", "MTK") {
    setTradeAfterBlock(_tradeAfterBlock);
  }

  /**
   * @dev The _mint function in the ERC20 contract is only internal,
   * therefore, we have to write a new function with public accessibility
   * to let the ICO contract call the mint function
   */
  function mint(address _to, uint _amount) public onlyOwner {
    _mint(_to, _amount);
  }

  /**
   * @dev Since the original _transfer function does not has the
   * ability to check either block.number >= tradeAfterBlock
   * or not, hence, we have to override the _transfer function
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint _amount
  ) internal override  {
    require(
      block.number >= tradeAfterBlock,
      "token not tradeable yet"
    );
    ERC20._transfer(_sender, _recipient, _amount);
  }

  /**
   * @dev Update the tradeAfterBlock
   * @param _tradeAfterBlock The new block number
   */
  function setTradeAfterBlock(uint _tradeAfterBlock) public onlyOwner {
    tradeAfterBlock = _tradeAfterBlock;
  }
}