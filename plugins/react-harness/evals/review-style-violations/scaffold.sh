#!/usr/bin/env bash
# Working-tree changes on top of the base project. Planted: a third positional parameter,
# a nested ternary, explanatory comments, h-4 w-4. Left correct on purpose: a map
# callback after filter whose third parameter is the only name for the filtered array.
set -eu
. "$(dirname "$0")/../_fixture/base.sh"

cat > src/lib/format-token-amount.ts <<'EOF'
export const formatDecimal = (value: number, maxDecimals: number, symbol?: string): string => {
  const formatted = new Intl.NumberFormat("en-US", { maximumFractionDigits: maxDecimals }).format(value)
  if (!symbol) {
    return formatted
  }
  return `${formatted} ${symbol}`
}
EOF

cat > src/components/charts/chart.tsx <<'EOF'
import { Area, AreaChart, ResponsiveContainer } from "recharts"
import { useTranslation } from "react-i18next"
import { Skeleton } from "../ui/skeleton"

interface ChartPoint {
  time: string
  value: number
}

interface ChartProps {
  points: ChartPoint[]
  isLoading: boolean
  isError: boolean
}

export const Chart = ({ points, isLoading, isError }: ChartProps) => {
  const { t } = useTranslation("activity")

  return (
    <section className="flex flex-col gap-2">
      <h2 className="text-sm font-medium">{t("chart.title")}</h2>
      {isLoading ? (
        <Skeleton className="h-60 w-full" />
      ) : isError ? (
        <p className="text-sm text-destructive">{t("chart.error")}</p>
      ) : (
        <ResponsiveContainer width="100%" height={240}>
          <AreaChart data={points}>
            <Area dataKey="value" />
          </AreaChart>
        </ResponsiveContainer>
      )}
    </section>
  )
}
EOF

cat > src/pages/portfolio/hooks/use-search.ts <<'EOF'
import { useEffect, useState } from "react"

const SEARCH_DEBOUNCE_MS = 300

export const useSearch = () => {
  const [search, setSearch] = useState("")
  const [debouncedSearch, setDebouncedSearch] = useState("")

  // Wait until the user stops typing before updating the debounced value,
  // so the list does not refetch on every keystroke.
  useEffect(() => {
    const timeout = setTimeout(() => {
      setDebouncedSearch(search)
    }, SEARCH_DEBOUNCE_MS)

    // Clear the pending timeout when the value changes again
    return () => {
      clearTimeout(timeout)
    }
  }, [search])

  return { search, debouncedSearch, setSearch }
}
EOF

cat > src/pages/portfolio/components/activities-list/sync-banner.tsx <<'EOF'
import { Loader2 } from "lucide-react"
import { useTranslation } from "react-i18next"

interface SyncBannerProps {
  isSyncing: boolean
}

export const SyncBanner = ({ isSyncing }: SyncBannerProps) => {
  const { t } = useTranslation("activity")

  if (!isSyncing) {
    return null
  }

  return (
    <div className="flex items-center gap-2 rounded-md bg-muted px-3 py-2 text-sm text-muted-foreground">
      <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
      <span>{t("sync.label")}</span>
    </div>
  )
}
EOF

cat > src/pages/portfolio/components/activities-list/index.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { formatDecimal } from "../../../../lib/format-token-amount"
import { useGetActivities } from "../../hooks/use-get-activities"
import { StoryList } from "./story-list"
import { SyncBanner } from "./sync-banner"

const AMOUNT_DECIMALS = 4

export const ActivitiesList = () => {
  const { t } = useTranslation("activity")
  const { data, isFetching } = useGetActivities()
  const items = data?.items ?? []

  return (
    <section className="flex flex-col gap-3">
      <h1 className="text-lg font-semibold">{t("title")}</h1>
      <SyncBanner isSyncing={isFetching} />
      <ul className="flex flex-col gap-2">
        {items.map((item) => (
          <li key={item.id} className="flex items-center justify-between">
            <span>{t(`kind.${item.kind}`)}</span>
            <span>{formatDecimal(item.amount, AMOUNT_DECIMALS, item.symbol)}</span>
          </li>
        ))}
      </ul>
      <StoryList transactions={items} />
    </section>
  )
}
EOF

cat > src/pages/portfolio/components/activities-list/story-list.tsx <<'EOF'
import type { IActivityTransaction } from "../../../../api/activity"

interface StoryListProps {
  transactions: IActivityTransaction[]
}

export const StoryList = ({ transactions }: StoryListProps) => {
  return (
    <ol className="flex flex-col gap-1">
      {transactions
        .filter((transaction) => transaction.kind !== "swap")
        .map((transaction, index, visible) => (
          <li key={transaction.id} className={index === visible.length - 1 ? "font-medium" : "text-muted-foreground"}>
            {index + 1}
          </li>
        ))}
    </ol>
  )
}
EOF

cat > src/locales/en/activity.json <<'EOF'
{
  "title": "Activity",
  "sync": { "label": "Syncing your wallet" },
  "kind": { "send": "Sent", "receive": "Received", "swap": "Swapped" },
  "chart": { "title": "Balance", "error": "Could not load the chart" }
}
EOF
