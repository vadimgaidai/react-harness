#!/usr/bin/env bash
# The project every case starts from: a small React app with an activity list, a chart and
# a shared query client, committed as one base commit. Sourced by each case's scaffold.sh.
# Synthetic; shaped after the kinds of files real review findings were made in.
set -eu

git init -q -b main .
git config user.email fixture@example.com
git config user.name fixture

mkdir -p src/lib src/locales/en src/api/activity src/components/ui src/components/charts \
  src/pages/portfolio/hooks src/pages/portfolio/components/activities-list

cat > package.json <<'EOF'
{
  "name": "fixture",
  "private": true,
  "type": "module",
  "dependencies": {
    "@tanstack/react-query": "^5.90.0",
    "i18next": "^25.0.0",
    "lucide-react": "^0.540.0",
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "react-i18next": "^16.0.0",
    "recharts": "^3.2.0",
    "tailwindcss": "^4.1.0"
  }
}
EOF

cat > openapi.json <<'EOF'
{
  "openapi": "3.0.3",
  "info": { "title": "Activity API", "version": "1.0.0" },
  "paths": {
    "/activities": {
      "get": {
        "parameters": [{ "name": "kind", "in": "query", "schema": { "$ref": "#/components/schemas/TransactionKind" } }],
        "responses": { "200": { "description": "ok", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ActivitiesListResponse" } } } } }
      }
    },
    "/activities/{hash}": {
      "get": {
        "parameters": [{ "name": "hash", "in": "path", "required": true, "schema": { "type": "string" } }],
        "responses": {
          "200": { "description": "ok", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ActivityTransaction" } } } },
          "404": { "description": "unknown hash" }
        }
      }
    },
    "/activities/{id}": {
      "patch": {
        "parameters": [{ "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }],
        "requestBody": { "content": { "application/json": { "schema": { "type": "object", "required": ["note"], "properties": { "note": { "type": "string" } } } } } },
        "responses": { "200": { "description": "the updated transaction", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ActivityTransaction" } } } } }
      }
    }
  },
  "components": {
    "schemas": {
      "TransactionKind": { "type": "string", "enum": ["send", "receive", "swap"] },
      "ActivityTransaction": {
        "type": "object",
        "required": ["id", "hash", "kind", "amount", "symbol", "createdAt"],
        "properties": {
          "id": { "type": "string" },
          "hash": { "type": "string" },
          "kind": { "$ref": "#/components/schemas/TransactionKind" },
          "amount": { "type": "number" },
          "symbol": { "type": "string" },
          "note": { "type": "string", "nullable": true },
          "createdAt": { "type": "string", "format": "date-time" }
        }
      },
      "ActivitiesListResponse": {
        "type": "object",
        "required": ["items", "total"],
        "properties": {
          "items": { "type": "array", "items": { "$ref": "#/components/schemas/ActivityTransaction" } },
          "total": { "type": "integer" }
        }
      }
    }
  }
}
EOF

cat > src/lib/http.ts <<'EOF'
export class HttpError extends Error {
  status: number

  constructor(status: number) {
    super(`request failed with ${status}`)
    this.status = status
  }
}

interface RequestOptions {
  method: "GET" | "PATCH" | "POST"
  path: string
  body?: unknown
}

const request = async <TResponse>({ method, path, body }: RequestOptions): Promise<TResponse> => {
  const response = await fetch(path, {
    method,
    headers: { "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!response.ok) {
    throw new HttpError(response.status)
  }
  return response.json()
}

export const http = {
  get: <TResponse>(path: string) => request<TResponse>({ method: "GET", path }),
  patch: <TResponse>(path: string, body: unknown) => request<TResponse>({ method: "PATCH", path, body }),
}
EOF

cat > src/lib/query-client.ts <<'EOF'
import { QueryClient } from "@tanstack/react-query"
import { HttpError } from "./http"

const MAX_RETRIES = 2
const CLIENT_ERROR_MIN = 400
const CLIENT_ERROR_MAX = 499
const STALE_TIME_MS = 60_000

const isClientError = (error: unknown) => {
  return error instanceof HttpError && error.status >= CLIENT_ERROR_MIN && error.status <= CLIENT_ERROR_MAX
}

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: STALE_TIME_MS,
      refetchOnWindowFocus: false,
      retry: (failureCount, error) => {
        if (isClientError(error)) {
          return false
        }
        return failureCount < MAX_RETRIES
      },
    },
    mutations: { retry: false },
  },
})
EOF

cat > src/lib/query-keys.ts <<'EOF'
type KeyBuilders = Record<string, (...args: never[]) => readonly unknown[]>

export const createQueryKeyFactory = <TBuilders extends KeyBuilders>(
  entity: string,
  build: (all: () => readonly [string]) => TBuilders,
) => {
  const all = () => [entity] as const
  return { all, ...build(all) }
}
EOF

cat > src/lib/format-token-amount.ts <<'EOF'
export const formatDecimal = (value: number, maxDecimals: number): string => {
  return new Intl.NumberFormat("en-US", { maximumFractionDigits: maxDecimals }).format(value)
}
EOF

cat > src/lib/i18n.ts <<'EOF'
import i18n from "i18next"
import { initReactI18next } from "react-i18next"
import activity from "../locales/en/activity.json"

void i18n.use(initReactI18next).init({
  lng: "en",
  resources: { en: { activity } },
})

export { i18n }
EOF

cat > src/locales/en/activity.json <<'EOF'
{
  "title": "Activity",
  "sync": { "label": "Syncing your wallet" },
  "kind": { "send": "Sent", "receive": "Received", "swap": "Swapped" },
  "chart": { "title": "Balance" }
}
EOF

cat > src/api/activity/types.ts <<'EOF'
export const TRANSACTION_KINDS = ["send", "receive", "swap"] as const

export type TransactionKind = (typeof TRANSACTION_KINDS)[number]

export interface IActivityTransaction {
  id: string
  hash: string
  kind: TransactionKind
  amount: number
  symbol: string
  note: string | null
  createdAt: string
}

export interface IActivitiesListResponse {
  items: IActivityTransaction[]
  total: number
}

export interface IActivityListFilters {
  kind?: TransactionKind
}
EOF

cat > src/api/activity/keys.ts <<'EOF'
import { createQueryKeyFactory } from "../../lib/query-keys"
import type { IActivityListFilters } from "./types"

const ACTIVITY_ENTITY = "activity"
const ACTIVITY_QUERY_KEYS = { LIST: "list" } as const

export const activityKeys = createQueryKeyFactory(ACTIVITY_ENTITY, (all) => ({
  lists: () => [...all(), ACTIVITY_QUERY_KEYS.LIST] as const,
  list: (filters: IActivityListFilters) => [...all(), ACTIVITY_QUERY_KEYS.LIST, filters] as const,
}))
EOF

cat > src/api/activity/api.ts <<'EOF'
import { http } from "../../lib/http"
import type { IActivitiesListResponse, IActivityListFilters } from "./types"

export const getActivities = (filters: IActivityListFilters): Promise<IActivitiesListResponse> => {
  const query = filters.kind ? `?kind=${filters.kind}` : ""
  return http.get<IActivitiesListResponse>(`/activities${query}`)
}
EOF

cat > src/api/activity/queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import { getActivities } from "./api"
import { activityKeys } from "./keys"
import type { IActivityListFilters } from "./types"

export const activityQueries = {
  list: (filters: IActivityListFilters) =>
    queryOptions({
      queryKey: activityKeys.list(filters),
      queryFn: () => getActivities(filters),
    }),
}
EOF

cat > src/api/activity/index.ts <<'EOF'
export { activityQueries } from "./queries"
export { activityKeys } from "./keys"
export { TRANSACTION_KINDS } from "./types"
export type { IActivitiesListResponse, IActivityListFilters, IActivityTransaction, TransactionKind } from "./types"
EOF

cat > src/components/ui/skeleton.tsx <<'EOF'
interface SkeletonProps {
  className?: string
}

export const Skeleton = ({ className }: SkeletonProps) => {
  return <div className={`animate-pulse rounded-md bg-muted ${className ?? ""}`} />
}
EOF

cat > src/components/ui/avatar.tsx <<'EOF'
interface AvatarProps {
  src: string
  alt: string
}

export const Avatar = ({ src, alt }: AvatarProps) => {
  return <img className="size-8 rounded-full" src={src} alt={alt} />
}
EOF

cat > src/components/charts/chart.tsx <<'EOF'
import { Area, AreaChart, ResponsiveContainer } from "recharts"
import { useTranslation } from "react-i18next"

interface ChartPoint {
  time: string
  value: number
}

interface ChartProps {
  points: ChartPoint[]
  isLoading: boolean
  isError: boolean
}

export const Chart = ({ points }: ChartProps) => {
  const { t } = useTranslation("activity")

  return (
    <section className="flex flex-col gap-2">
      <h2 className="text-sm font-medium">{t("chart.title")}</h2>
      <ResponsiveContainer width="100%" height={240}>
        <AreaChart data={points}>
          <Area dataKey="value" />
        </AreaChart>
      </ResponsiveContainer>
    </section>
  )
}
EOF

cat > src/components/charts/blur-swap-text.tsx <<'EOF'
interface BlurSwapTextProps {
  value: string
}

export const BlurSwapText = ({ value }: BlurSwapTextProps) => {
  return (
    <span className="relative inline-flex">
      <span className="transition-opacity duration-200">{value}</span>
    </span>
  )
}
EOF

cat > src/pages/portfolio/hooks/use-search.ts <<'EOF'
import { useState } from "react"

export const useSearch = () => {
  const [search, setSearch] = useState("")

  return { search, setSearch }
}
EOF

cat > src/pages/portfolio/hooks/use-get-activities.ts <<'EOF'
import { useQuery } from "@tanstack/react-query"
import { activityQueries } from "../../../api/activity"
import type { IActivityListFilters } from "../../../api/activity"

export const useGetActivities = () => {
  const filters: IActivityListFilters = {}
  const query = useQuery(activityQueries.list(filters))

  return { ...query }
}
EOF

cat > src/pages/portfolio/components/activities-list/sync-banner.tsx <<'EOF'
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
      <span>{t("sync.label")}</span>
    </div>
  )
}
EOF

cat > src/pages/portfolio/components/activities-list/index.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { formatDecimal } from "../../../../lib/format-token-amount"
import { useGetActivities } from "../../hooks/use-get-activities"
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
            <span>{formatDecimal(item.amount, AMOUNT_DECIMALS)}</span>
          </li>
        ))}
      </ul>
    </section>
  )
}
EOF

git add -A
git commit -q -m "base: activity list, chart and shared query client"
