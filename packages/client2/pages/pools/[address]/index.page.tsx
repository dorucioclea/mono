import { gql } from "@apollo/client";
import { BigNumber } from "ethers";
import { useRouter } from "next/router";
import { useEffect } from "react";

import {
  Breadcrumb,
  Button,
  Chip,
  Stat,
  TabButton,
  TabContent,
  TabGroup,
  TabList,
  TabPanels,
  Heading,
  Paragraph,
} from "@/components/design-system";
import { SEO } from "@/components/seo";
import { usdcFromAtomic } from "@/lib/format";
import { useSingleTranchedPoolDataLazyQuery } from "@/lib/graphql/generated";

import FundingBar from "./funding-bar";
import SupplyPanel from "./supply-panel";

export const TRANCHED_POOL_CARD_FIELDS = gql`
  query SingleTranchedPoolData($id: ID!) {
    tranchedPool(id: $id) {
      id
      name @client
      category @client
      icon @client
      description @client
      agreement @client
      dataroom @client
      poolDescription @client
      poolHighlights @client
      borrowerDescription @client
      borrowerHighlights @client
      estimatedJuniorApy
      estimatedJuniorApyFromGfiRaw
      estimatedJuniorApyFromGfi @client
      estimatedTotalAssets
      estimatedLeverageRatio
      remainingCapacity
      remainingJuniorCapacity
      juniorFeePercent
      reserveFeePercent
      totalDeposited
      totalDeployed
      fundableAt
      estimatedSeniorPoolContribution
      seniorTranches {
        principalDeposited
      }
      juniorTranches {
        principalDeposited
      }
      creditLine {
        limit
        maxLimit
        interestApr
        balance
        remainingPeriodDueAmount
        remainingTotalDueAmount
        availableCredit
        interestAccruedAsOf
        paymentPeriodInDays
        termInDays
        nextDueTime
        interestOwed
        termEndTime
        termStartTime
        lastFullPaymentTime
        periodDueAmount
        interestAprDecimal
        collectedPaymentBalance
        totalDueAmount
        dueDate
        isEligibleForRewards
        name
      }
    }
    gfi @client {
      price {
        usd
      }
    }
  }
`;

// Dummy data
const tags = [
  "Latin America",
  "Women-Owned Businesses",
  "Secured Loan",
  "Ethical Supply Chain",
  "Small Businesses",
];

export default function PoolPage() {
  const {
    query: { address },
  } = useRouter();

  const [getPoolData, { data }] = useSingleTranchedPoolDataLazyQuery();

  useEffect(() => {
    if (address) {
      getPoolData({ variables: { id: address as string } });
    }
  }, [getPoolData, address]);

  function share() {
    if (navigator && window) {
      navigator.share({
        title: data?.tranchedPool?.name || "Goldfinch",
        url: window.location.href,
      });
    }
  }

  return (
    <>
      <SEO title={data?.tranchedPool?.name} />

      <div className="mb-8 flex flex-row justify-between">
        <div>
          <Breadcrumb
            label={data?.tranchedPool?.name}
            image={data?.tranchedPool?.icon}
          />
        </div>
        <div>
          <Button size="sm" className="mr-2" onClick={share}>
            Share
          </Button>
          <Button size="sm" iconRight="ArrowTopRight" className="!py-2">
            Contract
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-10 ">
        <div className="col-span-8">
          <Heading level={1} className="mb-3 font-serif text-sand-800">
            {data?.tranchedPool?.name}
          </Heading>

          <div className="mb-12 flex flex-wrap gap-1">
            {tags.map((t) => (
              <Chip key={`tag-${t}`}>{t}</Chip>
            ))}
          </div>

          <div className="mb-15 grid grid-cols-3 rounded-lg border border-eggplant-50">
            <div className="col-span-3 border-b border-eggplant-50 p-5">
              <FundingBar
                goal={data?.tranchedPool?.creditLine?.maxLimit}
                backerSupply={data?.tranchedPool?.juniorTranches?.reduce(
                  (total, curr) => {
                    return total.add(curr.principalDeposited);
                  },
                  BigNumber.from(0)
                )}
                seniorSupply={data?.tranchedPool?.seniorTranches?.reduce(
                  (total, curr) => {
                    return total.add(curr.principalDeposited);
                  },
                  BigNumber.from(0)
                )}
              />
            </div>
            <div className="border-r border-eggplant-50 p-5">
              <Stat
                label="Drawdown cap"
                value={usdcFromAtomic(
                  data?.tranchedPool?.creditLine?.limit || BigNumber.from(0)
                )}
                tooltip={
                  <div>
                    <div className="mb-4 text-xl font-bold">Drawdown cap</div>
                    <div>
                      Lorem ipsum dolor, sit amet consectetur adipisicing elit.
                      Distinctio earum pariatur quod. Voluptatem mollitia
                      doloribus.
                    </div>
                  </div>
                }
              />
            </div>
            <div className="border-r border-eggplant-50 p-5">
              <Stat
                label="Payment Term"
                value={data?.tranchedPool?.creditLine?.termInDays.toString()}
                tooltip={
                  <div>
                    <div className="mb-4 text-xl font-bold">Payment Term</div>
                    <div>
                      Lorem ipsum dolor, sit amet consectetur adipisicing elit.
                      Distinctio earum pariatur quod. Voluptatem mollitia
                      doloribus.
                    </div>
                  </div>
                }
              />
            </div>
            <div className="p-5">
              <Stat
                label="Payment frequency"
                value={`${data?.tranchedPool?.creditLine?.paymentPeriodInDays.toString()} days`}
                tooltip={
                  <div>
                    <div className="mb-4 text-xl font-bold">
                      Payment frequency
                    </div>
                    <div>
                      Lorem ipsum dolor, sit amet consectetur adipisicing elit.
                      Distinctio earum pariatur quod. Voluptatem mollitia
                      doloribus.
                    </div>
                  </div>
                }
              />
            </div>
          </div>

          <div>
            <TabGroup>
              <TabList>
                <TabButton>Deal Overview</TabButton>
                <TabButton>Borrower Profile</TabButton>
              </TabList>
              <TabPanels>
                <TabContent>
                  <Heading level={3} className="mb-8 !text-4xl">
                    Overview
                  </Heading>
                  <Paragraph className="mb-10 whitespace-pre-wrap !text-2xl">
                    {data?.tranchedPool?.description}
                  </Paragraph>

                  <Heading level={4} className="mb-4 font-semibold">
                    Pool Overview
                  </Heading>
                  <Paragraph className="mb-10 whitespace-pre-wrap">
                    {data?.tranchedPool?.poolDescription}
                  </Paragraph>

                  <Heading level={4} className="mb-4 font-semibold">
                    Highlights
                  </Heading>
                  <ul className="list-outside list-disc pl-5">
                    {data?.tranchedPool?.poolHighlights?.map((item, idx) => (
                      <li
                        key={`pool-highlight-${address}-${idx}`}
                        className="py-1"
                      >
                        <Paragraph className="whitespace-pre-wrap">
                          {item}
                        </Paragraph>
                      </li>
                    ))}
                  </ul>
                </TabContent>
                <TabContent>
                  <Heading level={4} className="mb-4 font-semibold">
                    Overview
                  </Heading>
                  <Paragraph className="mb-10 whitespace-pre-wrap">
                    {data?.tranchedPool?.borrowerDescription}
                  </Paragraph>

                  <Heading level={4} className="mb-4 font-semibold">
                    Highlights
                  </Heading>
                  <ul className="list-outside list-disc pl-5">
                    {data?.tranchedPool?.borrowerHighlights?.map(
                      (item, idx) => (
                        <li
                          key={`borrower-highlight-${address}-${idx}`}
                          className="py-1"
                        >
                          <Paragraph className="whitespace-pre-wrap">
                            {item}
                          </Paragraph>
                        </li>
                      )
                    )}
                  </ul>
                </TabContent>
              </TabPanels>
            </TabGroup>
          </div>
        </div>

        <div className="relative col-span-4">
          <SupplyPanel
            apy={data?.tranchedPool?.estimatedJuniorApy}
            apyGfi={data?.tranchedPool?.estimatedJuniorApyFromGfi}
          />
        </div>
      </div>
    </>
  );
}
