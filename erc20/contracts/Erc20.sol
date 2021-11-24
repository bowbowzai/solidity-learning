pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
  constructor(uint initialSupply) ERC20("BOWBOW", "BOW") {
    _mint(msg.sender, initialSupply);
  }
}