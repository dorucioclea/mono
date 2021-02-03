// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../core/BaseUpgradeablePausable.sol";
import "../core/ConfigHelper.sol";
import "../core/CreditLine.sol";
import "../../interfaces/IERC20withDec.sol";

/**
 * @title Goldfinch's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Goldfinch
 */

contract Borrower is BaseUpgradeablePausable {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private constant BUSD_ADDRESS = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0), "Owner cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;

    // Handle default approvals. Pool, and OneInch for maximum amounts
    address oneInch = config.oneInchAddress();
    IERC20withDec usdc = config.getUSDC();
    usdc.approve(config.poolAddress(), uint256(-1));
    usdc.approve(oneInch, uint256(-1));
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    invoke(USDT_ADDRESS, data);
    data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    invoke(BUSD_ADDRESS, data);
  }

  /**
   * @notice Allows a borrower to drawdown on their creditline through the CreditDesk.
   * @param creditLineAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   * @param addressToSendTo The address where they would like the funds sent. If the zero address is passed,
   *  it will be defaulted to the contracts address (msg.sender). This is a convenience feature for when they would
   *  like the funds sent to an exchange or alternate wallet, different from the authentication address
   */
  function drawdown(
    address creditLineAddress,
    uint256 amount,
    address addressToSendTo
  ) external onlyAdmin {
    config.getCreditDesk().drawdown(creditLineAddress, amount);
    if (addressToSendTo != address(0) && addressToSendTo != address(this)) {
      transferUSDC(addressToSendTo, amount);
    }
  }

  function drawdownWithSwapOnOneInch(
    address creditLineAddress,
    uint256 amount,
    address addressToSendTo,
    address toToken,
    uint256 minTargetAmount,
    uint256[] memory exchangeDistribution
  ) public {
    // Drawdown to the Borrower contract
    config.getCreditDesk().drawdown(creditLineAddress, amount);

    // Do the swap
    swapOnOneInch(config.usdcAddress(), toToken, amount, minTargetAmount, exchangeDistribution);

    // Fulfill the send to
    if (addressToSendTo != address(0) && addressToSendTo != address(this)) {
      bytes memory _data = abi.encodeWithSignature("balanceOf(address)", address(this));
      uint256 receivedAmount = toUint256(invoke(toToken, _data));
      _data = abi.encodeWithSignature("transfer(address,uint256)", addressToSendTo, receivedAmount);
      invoke(toToken, _data);
    }
  }

  function transferUSDC(address to, uint256 amount) public onlyAdmin {
    bool success = config.getUSDC().transfer(to, amount);
    require(success, "Failed to transfer USDC");
  }

  /**
   * @notice Allows a borrower to payback loans by calling the `pay` function directly on the CreditDesk
   * @param creditLineAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that the borrower wishes to pay
   */
  function pay(address creditLineAddress, uint256 amount) external onlyAdmin {
    bool success = config.getUSDC().transferFrom(msg.sender, address(this), amount);
    require(success, "Failed to transfer USDC");
    config.getCreditDesk().pay(creditLineAddress, amount);
  }

  function payMultiple(address[] memory creditLines, uint256[] memory amounts) external onlyAdmin {
    require(creditLines.length == amounts.length, "Creditlines and amounts must be the same length");

    uint256 totalAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount += amounts[i];
    }

    // Do a single transfer, which is cheaper
    bool success = config.getUSDC().transferFrom(msg.sender, address(this), totalAmount);
    require(success, "Failed to transfer USDC");

    ICreditDesk creditDesk = config.getCreditDesk();
    for (uint256 i = 0; i < amounts.length; i++) {
      creditDesk.pay(creditLines[i], amounts[i]);
    }
  }

  function payInFull(address creditLineAddress, uint256 amount) external onlyAdmin {
    bool success = config.getUSDC().transferFrom(msg.sender, address(creditLineAddress), amount);
    require(success, "Failed to transfer USDC");

    config.getCreditDesk().applyPayment(creditLineAddress, amount);
    require(CreditLine(creditLineAddress).balance() == 0, "Failed to fully pay off creditline");
  }

  function payWithSwapOnOneInch(
    address creditLineAddress,
    uint256 originAmount,
    address fromToken,
    uint256 minTargetAmount,
    uint256[] memory exchangeDistribution
  ) external onlyAdmin {
    bytes memory _data;
    // Do a low-level invoke on this transfer, since Tether fails if we use the normal IERC20 interface
    _data = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), originAmount);
    invoke(address(fromToken), _data);
    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, minTargetAmount, exchangeDistribution);
    uint256 usdcBalance = usdc.balanceOf(address(this));
    config.getCreditDesk().pay(creditLineAddress, usdcBalance);
  }

  function swapOnOneInch(
    address fromToken,
    address toToken,
    uint256 originAmount,
    uint256 minTargetAmount,
    uint256[] memory exchangeDistribution
  ) internal {
    bytes memory _data = abi.encodeWithSignature(
      "swap(address,address,uint256,uint256,uint256[],uint256)",
      fromToken,
      toToken,
      originAmount,
      minTargetAmount,
      exchangeDistribution,
      0
    );
    invoke(config.oneInchAddress(), _data);
  }

  /**
   * @notice Performs a generic transaction.
   * @param _target The address for the transaction.
   * @param _data The data of the transaction.
   * Mostly copied from Argent:
   * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
   */
  function invoke(address _target, bytes memory _data) internal returns (bytes memory) {
    // External contracts can be compiled with different Solidity versions
    // which can cause "revert without reason" when called through,
    // for example, a standard IERC20 ABI compiled on the latest version.
    // This low-level call avoids that issue.

    bool success;
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = _target.call(_data);
    if (!success && _res.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else if (!success) {
      revert("VM: wallet invoke reverted");
    }
    return _res;
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }
}
