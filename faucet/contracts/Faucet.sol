pragma solidity >=0.7.0 <=0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is Ownable {
  event Deposit(address indexed from, uint amount);
  event Withdraw(address indexed to, uint amount);
  /**
   * @dev transfer 0.1 or less ether to the people who called
   * this function
   */
  function withdraw(uint _amount) external {
    require(
      _amount <= 0.1 ether,
      "only allowed withdraw more than 0.1 ether"
    );
    payable(msg.sender).transfer(_amount);
    emit Withdraw(msg.sender, _amount);
  }

  function kill() public onlyOwner {
    selfdestruct(payable(msg.sender));
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }
}