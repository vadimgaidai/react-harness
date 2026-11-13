#!/usr/bin/env bash
# Working-tree changes on top of the base project. Planted: an effect that copies a prop
# into state, a per-query retry override the shared client already covers, a cast where a
# guard belongs, a one-caller helper that only forwards. Left correct on purpose: a
# try/catch around JSON.parse of a stored value, which is a real boundary.
set -eu
. "$(dirname "$0")/../_fixture/base.sh"

cat > src/components/charts/blur-swap-text.tsx <<'EOF'
import { useEffect, useState } from "react"

interface BlurSwapTextProps {
  value: string
}

export const BlurSwapText = ({ value }: BlurSwapTextProps) => {
  const [current, setCurrent] = useState(value)
  const [previous, setPrevious] = useState(value)

  useEffect(() => {
    setPrevious(current)
    setCurrent(value)
  }, [value])

  return (
    <span className="relative inline-flex">
      <span className="absolute inset-0 opacity-0 transition-opacity duration-200">{previous}</span>
      <span className="transition-opacity duration-200">{current}</span>
    </span>
  )
}
EOF

cat > src/api/activity/keys.ts <<'EOF'
import { createQueryKeyFactory } from "../../lib/query-keys"
import type { IActivityListFilters } from "./types"

const ACTIVITY_ENTITY = "activity"
const ACTIVITY_QUERY_KEYS = { LIST: "list", BY_HASH: "by-hash" } as const

export const activityKeys = createQueryKeyFactory(ACTIVITY_ENTITY, (all) => ({
  lists: () => [...all(), ACTIVITY_QUERY_KEYS.LIST] as const,
  list: (filters: IActivityListFilters) => [...all(), ACTIVITY_QUERY_KEYS.LIST, filters] as const,
  byHash: (hash: string) => [...all(), ACTIVITY_QUERY_KEYS.BY_HASH, hash] as const,
}))
EOF

cat > src/api/activity/api.ts <<'EOF'
import { http } from "../../lib/http"
import type { IActivitiesListResponse, IActivityListFilters, IActivityTransaction } from "./types"

interface IUpdateActivityInput {
  id: string
  note: string
}

export const getActivities = (filters: IActivityListFilters): Promise<IActivitiesListResponse> => {
  const query = filters.kind ? `?kind=${filters.kind}` : ""
  return http.get<IActivitiesListResponse>(`/activities${query}`)
}

export const getActivityByHash = (hash: string): Promise<IActivityTransaction> => {
  return http.get<IActivityTransaction>(`/activities/${hash}`)
}

export const updateActivity = ({ id, note }: IUpdateActivityInput): Promise<IActivityTransaction> => {
  return http.patch<IActivityTransaction>(`/activities/${id}`, { note })
}
EOF

cat > src/api/activity/queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import { getActivities, getActivityByHash } from "./api"
import { activityKeys } from "./keys"
import type { IActivityListFilters } from "./types"

export const activityQueries = {
  list: (filters: IActivityListFilters) =>
    queryOptions({
      queryKey: activityKeys.list(filters),
      queryFn: () => getActivities(filters),
    }),
  byHash: (hash: string) =>
    queryOptions({
      queryKey: activityKeys.byHash(hash),
      queryFn: () => getActivityByHash(hash),
      retry: false,
    }),
}
EOF

cat > src/api/activity/invalidations.ts <<'EOF'
import type { QueryClient } from "@tanstack/react-query"
import { activityKeys } from "./keys"

export const invalidateActivityLists = (queryClient: QueryClient) => {
  return queryClient.invalidateQueries({ queryKey: activityKeys.lists() })
}
EOF

cat > src/api/activity/mutations.ts <<'EOF'
import { useMutation, useQueryClient } from "@tanstack/react-query"
import { updateActivity } from "./api"
import { invalidateActivityLists } from "./invalidations"

export const useUpdateActivity = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: updateActivity,
    onSuccess: () => {
      return invalidateActivityLists(queryClient)
    },
  })
}
EOF

cat > src/pages/portfolio/hooks/use-stored-kind.ts <<'EOF'
import { useState } from "react"
import { TRANSACTION_KINDS } from "../../../api/activity"
import type { TransactionKind } from "../../../api/activity"

const STORED_KIND_KEY = "activity-kind"

export const isTransactionKind = (value: unknown): value is TransactionKind => {
  return TRANSACTION_KINDS.some((kind) => kind === value)
}

const readStoredKind = (): TransactionKind | undefined => {
  const raw = localStorage.getItem(STORED_KIND_KEY)
  if (raw === null) {
    return undefined
  }
  try {
    const parsed: unknown = JSON.parse(raw)
    return isTransactionKind(parsed) ? parsed : undefined
  } catch {
    return undefined
  }
}

export const useStoredKind = () => {
  const [kind, setKind] = useState(readStoredKind)

  const selectKind = (next: TransactionKind | undefined) => {
    setKind(next)
    localStorage.setItem(STORED_KIND_KEY, JSON.stringify(next ?? null))
  }

  return { kind, selectKind }
}
EOF

cat > src/pages/portfolio/hooks/use-get-activities.ts <<'EOF'
import { useQuery } from "@tanstack/react-query"
import { activityQueries } from "../../../api/activity"
import type { TransactionKind } from "../../../api/activity"
import { useStoredKind } from "./use-stored-kind"

export const useGetActivities = () => {
  const { kind, selectKind } = useStoredKind()
  const query = useQuery(activityQueries.list({ kind }))

  const onKindChange = (value: string) => {
    selectKind(value as TransactionKind)
  }

  return { ...query, kind, onKindChange }
}
EOF

cat > src/pages/portfolio/components/activities-list/kind-filter.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { TRANSACTION_KINDS } from "../../../../api/activity"

interface KindFilterProps {
  value: string
  onChange: (value: string) => void
}

export const KindFilter = ({ value, onChange }: KindFilterProps) => {
  const { t } = useTranslation("activity")

  return (
    <select value={value} onChange={(event) => onChange(event.target.value)}>
      {TRANSACTION_KINDS.map((kind) => (
        <option key={kind} value={kind}>
          {t(`kind.${kind}`)}
        </option>
      ))}
    </select>
  )
}
EOF

cat > src/pages/portfolio/components/activities-list/index.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { formatDecimal } from "../../../../lib/format-token-amount"
import { useGetActivities } from "../../hooks/use-get-activities"
import { KindFilter } from "./kind-filter"
import { SyncBanner } from "./sync-banner"

const AMOUNT_DECIMALS = 4

export const ActivitiesList = () => {
  const { t } = useTranslation("activity")
  const { data, isFetching, kind, onKindChange } = useGetActivities()
  const items = data?.items ?? []

  return (
    <section className="flex flex-col gap-3">
      <h1 className="text-lg font-semibold">{t("title")}</h1>
      <KindFilter value={kind ?? ""} onChange={onKindChange} />
      <SyncBanner isSyncing={isFetching} />
      <ul className="flex flex-col gap-2">
        {items.map((item) => (
          <li key={item.id} className="flex items-center justify-between">
            <span>{t(`kind.${item.kind}`)}</span>
            <span>{formatDecimal(item.amount, AMOUNT_DECIMALS)}</span>
          </li>
        ))}
      </ul>
    </section>
  )
}
EOF
