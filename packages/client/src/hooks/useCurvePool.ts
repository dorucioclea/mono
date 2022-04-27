import {assertNonNullable} from "@goldfinch-eng/utils"
import BigNumber from "bignumber.js"
import {useContext} from "react"
import {AppContext} from "../App"
import {getMultiplier, Ticker} from "../ethereum/erc20"
import {useFromSameBlock} from "./useFromSameBlock"

type CurvePoolData = {
  estimateSlippage: (fiduAmount: BigNumber, usdcAmount: BigNumber) => Promise<BigNumber>
}

export default function useCurvePool(): CurvePoolData {
  const {pool: _pool, stakingRewards: _stakingRewards, currentBlock} = useContext(AppContext)
  const consistent = useFromSameBlock({setAsLeaf: false}, currentBlock, _pool, _stakingRewards)
  const pool = consistent?.[0]
  const stakingRewards = consistent?.[1]

  async function estimateSlippage(fiduAmount: BigNumber, usdcAmount: BigNumber): Promise<BigNumber> {
    assertNonNullable(stakingRewards)
    assertNonNullable(pool)

    const fiduSharePrice = new BigNumber(pool.info.value.poolData.sharePrice)
    const virtualPrice = stakingRewards.info.value.curveLPTokenPrice
    const estimatedTokensReceived = await stakingRewards.curvePool.readOnly.methods
      .calc_token_amount([fiduAmount.toString(10), usdcAmount.toString(10)])
      .call(undefined, "latest")

    const virtualValue = new BigNumber(estimatedTokensReceived)
      .times(new BigNumber(virtualPrice))
      .div(getMultiplier(Ticker.FIDU))

    const realValue = fiduAmount
      .times(fiduSharePrice)
      .div(getMultiplier(Ticker.FIDU))
      .plus(usdcAmount.times(getMultiplier(Ticker.FIDU)).div(getMultiplier(Ticker.USDC)))

    return virtualValue.div(realValue).minus(new BigNumber(1))
  }

  return {estimateSlippage}
}
