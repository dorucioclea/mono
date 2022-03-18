import {dataSource} from "@graphprotocol/graph-ts"

import {
  MAINNET_FIDU_ADDRESS,
  MAINNET_GOLDFINCH_CONFIG_ADDRESS,
  MAINNET_POOL_TOKENS_ADDRESS,
  MAINNET_SENIOR_POOL_ADDRESS,
} from "./mainnet-addresses"
import {
  LOCALHOST_FIDU_ADDRESS,
  LOCALHOST_GOLDFINCH_CONFIG_ADDRESS,
  LOCALHOST_POOL_TOKENS_ADDRESS,
  LOCALHOST_SENIOR_POOL_ADDRESS,
} from "./localhost-addresses"

export const V2_2_MIGRATION_TIME = "1643943600"

export let FIDU_ADDRESS = MAINNET_FIDU_ADDRESS
export let GOLDFINCH_CONFIG_ADDRESS = MAINNET_GOLDFINCH_CONFIG_ADDRESS
export let POOL_TOKENS_ADDRESS = MAINNET_POOL_TOKENS_ADDRESS
export let SENIOR_POOL_ADDRESS = MAINNET_SENIOR_POOL_ADDRESS

if (dataSource.network() == "localhost") {
  FIDU_ADDRESS = LOCALHOST_FIDU_ADDRESS
  SENIOR_POOL_ADDRESS = LOCALHOST_SENIOR_POOL_ADDRESS
  POOL_TOKENS_ADDRESS = LOCALHOST_POOL_TOKENS_ADDRESS
  GOLDFINCH_CONFIG_ADDRESS = LOCALHOST_GOLDFINCH_CONFIG_ADDRESS
}

// This config represents the enum config on protocol/core/ConfigOptions.sol where order is fixed
// (search for `library ConfigOptions` and `CONFIG_KEYS_BY_TYPE`)
export enum CONFIG_KEYS_NUMBERS {
  TransactionLimit = 0,
  TotalFundsLimit = 1,
  MaxUnderwriterLimit = 2,
  ReserveDenominator = 3,
  WithdrawFeeDenominator = 4,
  LatenessGracePeriodInDays = 5,
  LatenessMaxDays = 6,
  DrawdownPeriodInSeconds = 7,
  TransferRestrictionPeriodInDays = 8,
  LeverageRatio = 9,
}
export enum CONFIG_KEYS_ADDRESSES {
  Pool = 0,
  CreditLineImplementation = 1,
  GoldfinchFactory = 2,
  CreditDesk = 3,
  Fidu = 4,
  USDC = 5,
  TreasuryReserve = 6,
  ProtocolAdmin = 7,
  OneInch = 8,
  TrustedForwarder = 9,
  CUSDCContract = 10,
  GoldfinchConfig = 11,
  PoolTokens = 12,
  TranchedPoolImplementation = 13,
  SeniorPool = 14,
  SeniorPoolStrategy = 15,
  MigratedTranchedPoolImplementation = 16,
  BorrowerImplementation = 17,
  GFI = 18,
  Go = 19,
  BackerRewards = 20,
  StakingRewards = 21,
}
