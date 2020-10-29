// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";

contract Pool is BaseUpgradeablePausable, IPool {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 amount);
  event TransferMade(address indexed from, address indexed to, uint256 amount);
  event InterestCollected(address indexed payer, uint256 amount);
  event PrincipalCollected(address indexed payer, uint256 amount);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    __BaseUpgradeablePausable__init(owner);

    config = _config;
    sharePrice = fiduMantissa();
    IERC20withDec usdc = config.getUSDC();
    // Sanity check the address
    usdc.totalSupply();

    // Unlock self for infinite amount
    usdc.approve(address(this), uint256(-1));
  }

  function deposit(uint256 amount) external override whenNotPaused {
    // Check if the amount of new shares to be added is within limits
    uint256 depositShares = getNumShares(amount);
    uint256 potentialNewTotalShares = totalShares().add(depositShares);
    require(poolWithinLimit(potentialNewTotalShares), "Deposit would put the Pool over the total limit.");
    emit DepositMade(msg.sender, amount, depositShares);
    doUSDCTransfer(msg.sender, address(this), amount);
    config.getFidu().mintTo(msg.sender, depositShares);

    assert(assetsMatchLiabilities());
  }

  function withdraw(uint256 amount) external override whenNotPaused {
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = config.getFidu().balanceOf(msg.sender);
    uint256 withdrawShares = getNumShares(amount);
    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    emit WithdrawalMade(msg.sender, amount);
    // Send the amount to the address
    doUSDCTransfer(address(this), msg.sender, amount);

    // Burn the shares
    config.getFidu().burnFrom(msg.sender, withdrawShares);

    assert(assetsMatchLiabilities());
  }

  function collectInterestRepayment(address from, uint256 amount) external override onlyCreditDesk whenNotPaused {
    emit InterestCollected(from, amount);
    uint256 increment = usdcToFidu(amount).mul(fiduMantissa()).div(totalShares());
    sharePrice = sharePrice + increment;
    doUSDCTransfer(from, address(this), amount);
  }

  function collectPrincipalRepayment(address from, uint256 amount) external override onlyCreditDesk whenNotPaused {
    // Purposefully does nothing except receive money. No share price updates for principal.
    emit PrincipalCollected(from, amount);
    doUSDCTransfer(from, address(this), amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override onlyCreditDesk whenNotPaused returns (bool) {
    bool result = doUSDCTransfer(from, to, amount);
    emit TransferMade(from, to, amount);
    return result;
  }

  function enoughBalance(address user, uint256 amount) public override view whenNotPaused returns (bool) {
    return config.getUSDC().balanceOf(user) >= amount;
  }

  /* Internal Functions */

  function fiduMantissa() internal view returns (uint256) {
    return uint256(10)**uint256(config.getFidu().decimals());
  }

  function usdcMantissa() internal view returns (uint256) {
    return uint256(10)**uint256(config.getUSDC().decimals());
  }

  function usdcToFidu(uint256 amount) internal view returns (uint256) {
    return amount.mul(fiduMantissa()).div(usdcMantissa());
  }

  function totalShares() internal view returns (uint256) {
    return config.getFidu().totalSupply();
  }

  function poolWithinLimit(uint256 _totalShares) internal view returns (bool) {
    return
      _totalShares.mul(sharePrice).div(fiduMantissa()) <=
      usdcToFidu(config.getNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit)));
  }

  function transactionWithinLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.TransactionLimit));
  }

  function getNumShares(uint256 amount) internal view returns (uint256) {
    return usdcToFidu(amount).mul(fiduMantissa()).div(sharePrice);
  }

  function assetsMatchLiabilities() internal view returns (bool) {
    uint256 liabilities = config.getFidu().totalSupply().mul(config.getPool().sharePrice()).div(fiduMantissa());
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 assets = config.getUSDC().balanceOf(config.poolAddress())
      .add(config.getCreditDesk().totalLoansOutstanding())
      .sub(config.getCreditDesk().totalWritedowns());

    return liabilitiesInDollars == assets;
  }

  function fiduToUSDC(uint256 amount) internal view returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function doUSDCTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(transactionWithinLimit(amount), "Amount is over the per-transaction limit");
    IERC20withDec usdc = config.getUSDC();
    uint256 balanceBefore = usdc.balanceOf(to);

    bool success = usdc.transferFrom(from, to, amount);

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = usdc.balanceOf(to);
    require(balanceAfter >= balanceBefore, "Token Transfer Overflow Error");
    return success;
  }

  modifier onlyCreditDesk() {
    require(msg.sender == config.creditDeskAddress(), "Only the credit desk is allowed to call this function");
    _;
  }
}
