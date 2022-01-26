pragma solidity >=0.7.0 <0.9.0;

// Studied from https://medium.com@austin_48503%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
  using SafeMath for uint256;
  IERC20 token;
  uint256 public totalLiquidity;
  mapping(address => uint256) public liquidity;

  constructor(address _tokenAddress) {
    token = IERC20(_tokenAddress);
  }

  /**
   * @dev Send eth and erc20 token in the same time
   * when calling this function
   * @param _amount Amount of erc20 token
   */
  function init(uint256 _amount) public payable returns (uint256) {
    require(
      totalLiquidity == 0,
      "DEX already has liquidity!"
    );
    totalLiquidity = address(this).balance;
    liquidity[msg.sender] = totalLiquidity;
    require(
      token.transferFrom(msg.sender, address(this), _amount),
      "Transaction failed on init function"
    );
    return totalLiquidity;
  }

  function price(
    uint256 _inputAmount,
    uint256 _inputReserve,
    uint256 _outputReserve
  ) public view returns (uint256) {
    // inputAmountWithFee * 99.7%
    uint256 inputAmountWithFee = _inputAmount.mul(997);
    uint256 numerator = inputAmountWithFee.mul(_outputReserve);
    uint denominator = _inputReserve.mul(1000).add(inputAmountWithFee);
    return numerator / denominator;
  }

  function ethToToken() public payable returns (uint256) {
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 tokenBought = price(
      msg.value, address(this).balance.sub(msg.value), tokenReserve
    );
    require(
      token.transfer(msg.sender, tokenBought),
      "Transaction failed"
    );
    return tokenBought;
  }

  function tokenToEth(uint256 _amount) public returns (uint256) {
    uint256 ethBought = price(
      _amount, token.balanceOf(address(this)), address(this).balance
    );
    require(
      token.transferFrom(msg.sender, address(this), _amount),
      "Transaction failed"
    );
    payable(msg.sender).transfer(ethBought);
    return ethBought;
  }

  function deposit() public payable returns (uint256) {
    uint256 ethReserve = address(this).balance.sub(msg.value);
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 tokenAmountNeed = (msg.value.mul(tokenReserve) / ethReserve).add(1);
    uint256 liquidityMinted = msg.value.mul(totalLiquidity) / ethReserve;
    liquidity[msg.sender] = liquidity[msg.sender].add(liquidityMinted);
    totalLiquidity = totalLiquidity.add(liquidityMinted);
    require(
      token.transferFrom(msg.sender, address(this), tokenAmountNeed),
      "Transaction failed"
    );
    return liquidityMinted;
  }

  function withdraw(uint256 _amount) public returns (uint256, uint256) {
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 ethAmount = _amount.mul(address(this).balance) / totalLiquidity;
    uint256 tokenAmount = _amount.mul(tokenReserve) / totalLiquidity;
    liquidity[msg.sender] = liquidity[msg.sender].sub(ethAmount);
    totalLiquidity = totalLiquidity.sub(ethAmount);
    payable(msg.sender).transfer(ethAmount);
    require(token.transfer(msg.sender, tokenAmount));
    return (ethAmount, tokenAmount);
  }
}