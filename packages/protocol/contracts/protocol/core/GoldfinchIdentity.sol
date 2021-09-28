// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../../external/ERC1155PresetPauserUpgradeable.sol";
import "../../interfaces/IGoldfinchIdentity.sol";

/**
 * @title GoldfinchIdentity
 * @notice GoldfinchIdentity is an ERC1155-compliant contract for representing
 * the identity verification status of addresses.
 * @author Goldfinch
 */

contract GoldfinchIdentity is ERC1155PresetPauserUpgradeable, IGoldfinchIdentity {
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  mapping(address => uint256) public nonces;

  /// TODO[PR] Do we need to worry about OZ automatically setting owner as msg.sender? (See PoolTokens.)

  function initialize(string memory uri) public override(ERC1155PresetPauserUpgradeable) initializer {
    super.initialize(uri);
    __GoldfinchIdentity_init(uri);
  }

  function __GoldfinchIdentity_init(string memory uri) internal initializer {
    __GoldfinchIdentity_init_unchained(uri);
  }

  function __GoldfinchIdentity_init_unchained(string memory uri) internal initializer {
    _setupRole(SIGNER_ROLE, _msgSender());
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data,
    bytes memory signature
  ) public override(IGoldfinchIdentity) onlySigner(keccak256(abi.encodePacked(to, id, amount, nonces[to])), signature) {
    require(id == 0, "Token id not supported");
    require(amount > 0, "Amount must be greater than 0");

    nonces[to] += 1;
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data,
    bytes memory signature
  )
    public
    override(IGoldfinchIdentity)
    onlySigner(keccak256(abi.encodePacked(to, ids, amounts, nonces[to])), signature)
  {
    uint256 length = amounts.length;
    require(ids.length == length, "ids and amounts length mismatch");
    for (uint256 i = 0; i < length; i++) {
      require(ids[i] == 0, "Token id not supported");
      require(amounts[i] > 0, "Amount must be greater than 0");
    }

    nonces[to] += 1;
    _mintBatch(to, ids, amounts, data);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override(ERC1155Upgradeable, IERC1155Upgradeable) {
    require(false, "Transfer is disabled");
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override(ERC1155Upgradeable, IERC1155Upgradeable) {
    require(false, "Transfer is disabled");
  }

  function burn(
    address account,
    uint256 id,
    uint256 value,
    bytes memory signature
  ) public override onlySigner(keccak256(abi.encodePacked(account, id, value, nonces[account])), signature) {
    nonces[account] += 1;
    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory signature
  ) public override onlySigner(keccak256(abi.encodePacked(account, ids, values, nonces[account])), signature) {
    nonces[account] += 1;
    _burnBatch(account, ids, values);
  }

  modifier onlySigner(bytes32 hash, bytes memory signature) {
    require(hasRole(SIGNER_ROLE, ECDSAUpgradeable.recover(hash, signature)), "Invalid signer");
    _;
  }
}
