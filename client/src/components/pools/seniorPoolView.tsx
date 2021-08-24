import {useState, useEffect, useContext} from "react"
import EarnActionsContainer from "../earnActionsContainer"
import PoolStatus from "../poolStatus"
import ConnectionNotice from "../connectionNotice"
import {
  CapitalProvider,
  emptyCapitalProvider,
  fetchCapitalProviderData,
  PoolData,
  SeniorPool,
} from "../../ethereum/pool"
import {AppContext} from "../../App"
import InvestorNotice from "../investorNotice"

function SeniorPoolView() {
  const {pool, user} = useContext(AppContext)
  const [capitalProvider, setCapitalProvider] = useState<CapitalProvider>(emptyCapitalProvider())
  const [poolData, setPoolData] = useState<PoolData>()

  useEffect(() => {
    async function refreshAllData() {
      const capitalProviderAddress = user.loaded && user.address
      refreshPoolData(pool!)
      refreshCapitalProviderData(pool, capitalProviderAddress)
    }

    if (pool) {
      refreshAllData()
    }
  }, [pool, user])

  async function actionComplete() {
    await refreshPoolData(pool!)
    return refreshCapitalProviderData(pool, capitalProvider!.address)
  }

  async function refreshCapitalProviderData(pool: any, address: string | boolean) {
    const capitalProvider = await fetchCapitalProviderData(pool, address)
    setCapitalProvider(capitalProvider)
  }

  async function refreshPoolData(pool: SeniorPool) {
    await pool.initialize()
    setPoolData(pool.gf)
  }

  let earnMessage = "Loading..."
  if (capitalProvider.loaded || user.noWeb3) {
    earnMessage = "Earn Portfolio / Senior Pool"
  }

  return (
    <div className="content-section">
      <div className="page-header"> {earnMessage}</div>
      <ConnectionNotice requireVerify={true} />
      <InvestorNotice />
      <EarnActionsContainer poolData={poolData} capitalProvider={capitalProvider} actionComplete={actionComplete} />
      <PoolStatus poolData={poolData} />
    </div>
  )
}

export default SeniorPoolView
