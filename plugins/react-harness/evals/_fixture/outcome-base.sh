#!/usr/bin/env bash
# The clean project the outcome cases start from, laid out by the feature-folders structure: a
# portfolio page module with an activity list read through useSuspenseQuery and a QueryBoundary,
# shadcn/ui primitives, a shared query client and a contract. Unlike base.sh it carries no
# planted defects, so what a run writes is the model's own and not a copy of a neighbour.
# Sourced by each outcome case's scaffold.sh.
set -eu

git init -q -b main .
git config user.email fixture@example.com
git config user.name fixture

mkdir -p src/lib src/locales/en src/api/activity src/components/ui \
  src/pages/portfolio/components

cat > package.json <<'EOF'
{
  "name": "fixture",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite"
  },
  "dependencies": {
    "@tanstack/react-query": "^5.90.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "i18next": "^25.0.0",
    "lucide-react": "^0.540.0",
    "radix-ui": "^1.4.3",
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "react-error-boundary": "^6.0.0",
    "react-i18next": "^16.0.0",
    "recharts": "^2.15.4",
    "sonner": "^2.0.7",
    "tailwind-merge": "^3.3.1",
    "tailwindcss": "^4.1.0"
  },
  "devDependencies": {
    "@types/react": "^19.2.0",
    "@types/react-dom": "^19.2.0",
    "@vitejs/plugin-react": "^5.0.0",
    "typescript": "^5.9.0",
    "vite": "^7.1.0"
  }
}
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "resolveJsonModule": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"]
}
EOF

cat > components.json <<'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "base": "radix",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
EOF

cat > src/index.css <<'EOF'
@import "tailwindcss";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.205 0 0);
  --card-foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.556 0 0);
  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
  --chart-3: oklch(0.769 0.188 70.08);
  --chart-4: oklch(0.627 0.265 303.9);
  --chart-5: oklch(0.645 0.246 16.439);
}

@theme inline {
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-chart-1: var(--chart-1);
  --color-chart-2: var(--chart-2);
  --color-chart-3: var(--chart-3);
  --color-chart-4: var(--chart-4);
  --color-chart-5: var(--chart-5);
}

@layer base {
  * {
    @apply border-border outline-ring/50;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

cat > openapi.json <<'EOF'
{
  "openapi": "3.0.3",
  "info": { "title": "Portfolio API", "version": "1.0.0" },
  "paths": {
    "/activities": {
      "get": {
        "parameters": [{ "name": "kind", "in": "query", "schema": { "$ref": "#/components/schemas/TransactionKind" } }],
        "responses": { "200": { "description": "ok", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ActivitiesListResponse" } } } } }
      }
    },
    "/portfolio/history": {
      "get": {
        "summary": "Balance of the portfolio over time",
        "parameters": [{ "name": "range", "in": "query", "required": true, "schema": { "$ref": "#/components/schemas/HistoryRange" } }],
        "responses": {
          "200": { "description": "ok", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/PortfolioHistoryResponse" } } } },
          "400": { "description": "unknown range" }
        }
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
      },
      "HistoryRange": { "type": "string", "enum": ["7d", "30d", "90d"] },
      "BalancePoint": {
        "type": "object",
        "required": ["timestamp", "balance"],
        "properties": {
          "timestamp": { "type": "string", "format": "date-time" },
          "balance": { "type": "number", "description": "total balance in the portfolio currency" }
        }
      },
      "PortfolioHistoryResponse": {
        "type": "object",
        "required": ["range", "currency", "points"],
        "properties": {
          "range": { "$ref": "#/components/schemas/HistoryRange" },
          "currency": { "type": "string", "description": "ISO 4217 code, e.g. USD" },
          "points": { "type": "array", "items": { "$ref": "#/components/schemas/BalancePoint" }, "description": "oldest first; empty when the portfolio has no history in the range" }
        }
      }
    }
  }
}
EOF

cat > src/lib/utils.ts <<'EOF'
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export const cn = (...inputs: ClassValue[]) => twMerge(clsx(inputs))
EOF

cat > src/lib/http.ts <<'EOF'
export class HttpError extends Error {
  status: number

  constructor(status: number) {
    super(`request failed with ${status}`)
    this.status = status
  }
}

type THttpMethod = "GET" | "PATCH" | "POST"

interface IRequestOptions {
  method: THttpMethod
  path: string
  body?: unknown
}

const request = async <TResponse>({ method, path, body }: IRequestOptions): Promise<TResponse> => {
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

const isClientError = (error: unknown): boolean => {
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

cat > src/lib/query.ts <<'EOF'
type TKeyBuilders = Record<string, (...args: never[]) => readonly unknown[]>

export const createQueryKeyFactory = <TBuilders extends TKeyBuilders>(
  entity: string,
  build: (all: () => readonly [string]) => TBuilders,
) => {
  const all = () => [entity] as const
  return { all, ...build(all) }
}
EOF

cat > src/lib/i18n.ts <<'EOF'
import i18n from "i18next"
import { initReactI18next } from "react-i18next"
import activity from "@/locales/en/activity.json"
import portfolio from "@/locales/en/portfolio.json"

void i18n.use(initReactI18next).init({
  lng: "en",
  resources: { en: { activity, portfolio } },
})

export { i18n }
EOF

cat > src/locales/en/activity.json <<'EOF'
{
  "title": "Activity",
  "kind": { "send": "Sent", "receive": "Received", "swap": "Swapped" },
  "amount": "{{value, number}}",
  "empty": { "title": "No activity yet", "description": "Transactions show up here once you send or receive." },
  "errors": { "load": "Could not load your activity.", "refetch": "Could not refresh your activity." },
  "actions": { "retry": "Try again" }
}
EOF

cat > src/locales/en/portfolio.json <<'EOF'
{
  "title": "Portfolio"
}
EOF

cat > src/api/activity/types.ts <<'EOF'
export const TRANSACTION_KINDS = ["send", "receive", "swap"] as const

export type TTransactionKind = (typeof TRANSACTION_KINDS)[number]

export interface IActivityTransaction {
  id: string
  hash: string
  kind: TTransactionKind
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
  kind?: TTransactionKind
}
EOF

cat > src/api/activity/activity.api.ts <<'EOF'
import type { IActivitiesListResponse, IActivityListFilters } from "./types"

import { http } from "@/lib/http"

const ACTIVITIES_PATH = "/activities"

export const activityApi = {
  getList: ({ kind }: IActivityListFilters) => {
    const search = kind ? `?${new URLSearchParams({ kind })}` : ""
    return http.get<IActivitiesListResponse>(`${ACTIVITIES_PATH}${search}`)
  },
}
EOF

cat > src/api/activity/activity.queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import type { IActivityListFilters } from "./types"

import { activityApi } from "./activity.api"
import { createQueryKeyFactory } from "@/lib/query"

const ACTIVITY_QUERY_KEYS = { LIST: "list" } as const

export const activityKeys = createQueryKeyFactory("activity", (all) => ({
  lists: () => [...all(), ACTIVITY_QUERY_KEYS.LIST] as const,
  list: (filters: IActivityListFilters) => [...all(), ACTIVITY_QUERY_KEYS.LIST, filters] as const,
}))

export const activityQueries = {
  list: (filters: IActivityListFilters) =>
    queryOptions({
      queryKey: activityKeys.list(filters),
      queryFn: () => activityApi.getList(filters),
    }),
}
EOF

cat > src/api/activity/index.ts <<'EOF'
export { activityApi } from "./activity.api"
export { activityKeys, activityQueries } from "./activity.queries"
export { TRANSACTION_KINDS } from "./types"
export type { IActivitiesListResponse, IActivityListFilters, IActivityTransaction, TTransactionKind } from "./types"
EOF

cat > src/components/ui/button.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Slot } from "radix-ui"
import { cn } from "@/lib/utils"

export const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center gap-2 rounded-md text-sm font-medium whitespace-nowrap transition-all outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-white hover:bg-destructive/90",
        outline: "border bg-background hover:bg-accent hover:text-accent-foreground",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2 has-[>svg]:px-3",
        sm: "h-8 gap-1.5 rounded-md px-3 has-[>svg]:px-2.5",
        lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
        icon: "size-9",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
)

export const Button = ({
  className,
  variant,
  size,
  asChild = false,
  ...props
}: ComponentProps<"button"> & VariantProps<typeof buttonVariants> & { asChild?: boolean }) => {
  const Comp = asChild ? Slot.Root : "button"
  return <Comp data-slot="button" className={cn(buttonVariants({ variant, size, className }))} {...props} />
}
EOF

cat > src/components/ui/card.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cn } from "@/lib/utils"

export const Card = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card" className={cn("flex flex-col gap-6 rounded-xl border bg-card py-6 text-card-foreground shadow-sm", className)} {...props} />
)

export const CardHeader = ({ className, ...props }: ComponentProps<"div">) => (
  <div
    data-slot="card-header"
    className={cn("grid auto-rows-min grid-rows-[auto_auto] items-start gap-1.5 px-6 has-data-[slot=card-action]:grid-cols-[1fr_auto]", className)}
    {...props}
  />
)

export const CardTitle = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card-title" className={cn("leading-none font-semibold", className)} {...props} />
)

export const CardDescription = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card-description" className={cn("text-sm text-muted-foreground", className)} {...props} />
)

export const CardAction = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card-action" className={cn("col-start-2 row-span-2 row-start-1 self-start justify-self-end", className)} {...props} />
)

export const CardContent = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card-content" className={cn("px-6", className)} {...props} />
)

export const CardFooter = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="card-footer" className={cn("flex items-center px-6", className)} {...props} />
)
EOF

cat > src/components/ui/toggle.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Toggle as TogglePrimitive } from "radix-ui"
import { cn } from "@/lib/utils"

export const toggleVariants = cva(
  "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium whitespace-nowrap transition-[color,box-shadow] outline-none hover:bg-muted hover:text-muted-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 data-[state=on]:bg-accent data-[state=on]:text-accent-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
  {
    variants: {
      variant: {
        default: "bg-transparent",
        outline: "border border-input bg-transparent shadow-xs hover:bg-accent hover:text-accent-foreground",
      },
      size: {
        default: "h-9 min-w-9 px-2",
        sm: "h-8 min-w-8 px-1.5",
        lg: "h-10 min-w-10 px-2.5",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
)

export const Toggle = ({
  className,
  variant,
  size,
  ...props
}: ComponentProps<typeof TogglePrimitive.Root> & VariantProps<typeof toggleVariants>) => (
  <TogglePrimitive.Root data-slot="toggle" className={cn(toggleVariants({ variant, size, className }))} {...props} />
)
EOF

cat > src/components/ui/toggle-group.tsx <<'EOF'
import { createContext, useContext, type ComponentProps } from "react"
import type { VariantProps } from "class-variance-authority"
import { ToggleGroup as ToggleGroupPrimitive } from "radix-ui"
import { toggleVariants } from "@/components/ui/toggle"
import { cn } from "@/lib/utils"

const ToggleGroupContext = createContext<VariantProps<typeof toggleVariants>>({
  size: "default",
  variant: "default",
})

export const ToggleGroup = ({
  className,
  variant,
  size,
  children,
  ...props
}: ComponentProps<typeof ToggleGroupPrimitive.Root> & VariantProps<typeof toggleVariants>) => (
  <ToggleGroupPrimitive.Root
    data-slot="toggle-group"
    data-variant={variant}
    data-size={size}
    className={cn("group/toggle-group flex w-fit items-center rounded-md data-[variant=outline]:shadow-xs", className)}
    {...props}
  >
    <ToggleGroupContext.Provider value={{ variant, size }}>{children}</ToggleGroupContext.Provider>
  </ToggleGroupPrimitive.Root>
)

export const ToggleGroupItem = ({
  className,
  children,
  variant,
  size,
  ...props
}: ComponentProps<typeof ToggleGroupPrimitive.Item> & VariantProps<typeof toggleVariants>) => {
  const context = useContext(ToggleGroupContext)
  return (
    <ToggleGroupPrimitive.Item
      data-slot="toggle-group-item"
      className={cn(
        toggleVariants({ variant: context.variant || variant, size: context.size || size }),
        "min-w-0 flex-1 shrink-0 rounded-none shadow-none first:rounded-s-md last:rounded-e-md focus:z-10 focus-visible:z-10 data-[variant=outline]:border-s-0 data-[variant=outline]:first:border-s",
        className,
      )}
      {...props}
    >
      {children}
    </ToggleGroupPrimitive.Item>
  )
}
EOF

cat > src/components/ui/skeleton.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cn } from "@/lib/utils"

export const Skeleton = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="skeleton" className={cn("animate-pulse rounded-md bg-accent", className)} {...props} />
)
EOF

cat > src/components/ui/alert.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const alertVariants = cva(
  "relative grid w-full grid-cols-[0_1fr] items-start gap-y-0.5 rounded-lg border px-4 py-3 text-sm has-[>svg]:grid-cols-[calc(var(--spacing)*4)_1fr] has-[>svg]:gap-x-3 [&>svg]:size-4 [&>svg]:translate-y-0.5 [&>svg]:text-current",
  {
    variants: {
      variant: {
        default: "bg-card text-card-foreground",
        destructive: "bg-card text-destructive *:data-[slot=alert-description]:text-destructive/90 [&>svg]:text-current",
      },
    },
    defaultVariants: { variant: "default" },
  },
)

export const Alert = ({ className, variant, ...props }: ComponentProps<"div"> & VariantProps<typeof alertVariants>) => (
  <div data-slot="alert" role="alert" className={cn(alertVariants({ variant }), className)} {...props} />
)

export const AlertTitle = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="alert-title" className={cn("col-start-2 line-clamp-1 min-h-4 font-medium tracking-tight", className)} {...props} />
)

export const AlertDescription = ({ className, ...props }: ComponentProps<"div">) => (
  <div
    data-slot="alert-description"
    className={cn("col-start-2 grid justify-items-start gap-1 text-sm text-muted-foreground [&_p]:leading-relaxed", className)}
    {...props}
  />
)
EOF

cat > src/components/ui/empty.tsx <<'EOF'
import type { ComponentProps } from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

export const Empty = ({ className, ...props }: ComponentProps<"div">) => (
  <div
    data-slot="empty"
    className={cn("flex min-w-0 flex-1 flex-col items-center justify-center gap-6 rounded-lg border-dashed p-6 text-center text-balance md:p-12", className)}
    {...props}
  />
)

export const EmptyHeader = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="empty-header" className={cn("flex max-w-sm flex-col items-center gap-2 text-center", className)} {...props} />
)

const emptyMediaVariants = cva("mb-2 flex shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg]:shrink-0", {
  variants: {
    variant: {
      default: "bg-transparent",
      icon: "flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted text-foreground [&_svg:not([class*='size-'])]:size-6",
    },
  },
  defaultVariants: { variant: "default" },
})

export const EmptyMedia = ({ className, variant = "default", ...props }: ComponentProps<"div"> & VariantProps<typeof emptyMediaVariants>) => (
  <div data-slot="empty-icon" data-variant={variant} className={cn(emptyMediaVariants({ variant, className }))} {...props} />
)

export const EmptyTitle = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="empty-title" className={cn("text-lg font-medium tracking-tight", className)} {...props} />
)

export const EmptyDescription = ({ className, ...props }: ComponentProps<"p">) => (
  <div data-slot="empty-description" className={cn("text-sm/relaxed text-muted-foreground", className)} {...props} />
)

export const EmptyContent = ({ className, ...props }: ComponentProps<"div">) => (
  <div data-slot="empty-content" className={cn("flex w-full max-w-sm min-w-0 flex-col items-center gap-4 text-sm text-balance", className)} {...props} />
)
EOF

cat > src/components/ui/sonner.tsx <<'EOF'
import { Toaster as Sonner, type ToasterProps } from "sonner"

export const Toaster = (props: ToasterProps) => <Sonner className="toaster group" {...props} />
EOF

cat > src/components/ui/chart.tsx <<'EOF'
import { createContext, useContext, useId, type ComponentProps, type ComponentType, type ReactNode } from "react"
import * as RechartsPrimitive from "recharts"
import { cn } from "@/lib/utils"

const THEMES = { light: "", dark: ".dark" } as const

export type ChartConfig = {
  [k in string]: {
    label?: ReactNode
    icon?: ComponentType
  } & ({ color?: string; theme?: never } | { color?: never; theme: Record<keyof typeof THEMES, string> })
}

type ChartContextProps = {
  config: ChartConfig
}

const ChartContext = createContext<ChartContextProps | null>(null)

const useChart = () => {
  const context = useContext(ChartContext)
  if (!context) {
    throw new Error("useChart must be used within a <ChartContainer />")
  }
  return context
}

const ChartStyle = ({ id, config }: { id: string; config: ChartConfig }) => {
  const colorConfig = Object.entries(config).filter(([, item]) => item.theme || item.color)
  if (!colorConfig.length) {
    return null
  }
  return (
    <style
      dangerouslySetInnerHTML={{
        __html: Object.entries(THEMES)
          .map(
            ([theme, prefix]) => `
${prefix} [data-chart=${id}] {
${colorConfig
  .map(([key, itemConfig]) => {
    const color = itemConfig.theme?.[theme as keyof typeof itemConfig.theme] || itemConfig.color
    return color ? `  --color-${key}: ${color};` : null
  })
  .join("\n")}
}
`,
          )
          .join("\n"),
      }}
    />
  )
}

export const ChartContainer = ({
  id,
  className,
  children,
  config,
  ...props
}: ComponentProps<"div"> & {
  config: ChartConfig
  children: ComponentProps<typeof RechartsPrimitive.ResponsiveContainer>["children"]
}) => {
  const uniqueId = useId()
  const chartId = `chart-${id || uniqueId.replace(/:/g, "")}`

  return (
    <ChartContext.Provider value={{ config }}>
      <div
        data-slot="chart"
        data-chart={chartId}
        className={cn(
          "flex aspect-video justify-center text-xs [&_.recharts-cartesian-axis-tick_text]:fill-muted-foreground [&_.recharts-cartesian-grid_line[stroke='#ccc']]:stroke-border/50 [&_.recharts-curve.recharts-tooltip-cursor]:stroke-border [&_.recharts-layer]:outline-hidden [&_.recharts-surface]:outline-hidden",
          className,
        )}
        {...props}
      >
        <ChartStyle id={chartId} config={config} />
        <RechartsPrimitive.ResponsiveContainer>{children}</RechartsPrimitive.ResponsiveContainer>
      </div>
    </ChartContext.Provider>
  )
}

export const ChartTooltip = RechartsPrimitive.Tooltip

export const ChartTooltipContent = ({
  active,
  payload,
  className,
  hideLabel = false,
  label,
  labelFormatter,
  formatter,
  nameKey,
}: ComponentProps<typeof RechartsPrimitive.Tooltip> &
  ComponentProps<"div"> & {
    hideLabel?: boolean
    nameKey?: string
  }) => {
  const { config } = useChart()

  if (!active || !payload?.length) {
    return null
  }

  return (
    <div className={cn("grid min-w-32 items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl", className)}>
      {!hideLabel && <div className="font-medium">{labelFormatter ? labelFormatter(label, payload) : label}</div>}
      <div className="grid gap-1.5">
        {payload.map((item, index) => {
          const key = `${nameKey || item.name || item.dataKey || "value"}`
          const itemConfig = config[key]
          return (
            <div key={key} className="flex w-full items-center gap-2">
              <div className="size-2.5 shrink-0 rounded-[2px]" style={{ backgroundColor: item.color }} />
              <div className="flex flex-1 justify-between gap-4 leading-none">
                <span className="text-muted-foreground">{itemConfig?.label || item.name}</span>
                <span className="font-mono font-medium text-foreground tabular-nums">
                  {formatter && item.value !== undefined && item.name ? formatter(item.value, item.name, item, index, item.payload) : item.value}
                </span>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
EOF

cat > src/components/query-boundary.tsx <<'EOF'
import { Suspense, type ComponentType, type ReactNode } from "react"
import { QueryErrorResetBoundary } from "@tanstack/react-query"
import { ErrorBoundary, type FallbackProps } from "react-error-boundary"

interface IQueryBoundaryProps {
  fallback: ReactNode
  errorFallback: ComponentType<FallbackProps>
  children: ReactNode
}

export const QueryBoundary = ({ fallback, errorFallback, children }: IQueryBoundaryProps) => (
  <QueryErrorResetBoundary>
    {({ reset }) => (
      <ErrorBoundary FallbackComponent={errorFallback} onReset={reset}>
        <Suspense fallback={fallback}>{children}</Suspense>
      </ErrorBoundary>
    )}
  </QueryErrorResetBoundary>
)
EOF

cat > src/pages/portfolio/components/activity-row.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import type { IActivityTransaction } from "@/api/activity"

interface IActivityRowProps {
  transaction: IActivityTransaction
}

export const ActivityRow = ({ transaction }: IActivityRowProps) => {
  const { t } = useTranslation("activity")

  return (
    <li className="flex items-center justify-between gap-4 py-2">
      <span className="text-sm">{t(`kind.${transaction.kind}`)}</span>
      <span className="font-mono text-sm tabular-nums">
        {t("amount", { value: transaction.amount })} {transaction.symbol}
      </span>
    </li>
  )
}
EOF

cat > src/pages/portfolio/components/activities-skeleton.tsx <<'EOF'
import { Skeleton } from "@/components/ui/skeleton"
import { SKELETON_ROWS } from "../constants"

export const ActivitiesSkeleton = () => (
  <div className="flex flex-col gap-2">
    {Array.from({ length: SKELETON_ROWS }, (_, index) => (
      <Skeleton key={index} className="h-6 w-full" />
    ))}
  </div>
)
EOF

cat > src/pages/portfolio/components/activities-error.tsx <<'EOF'
import { AlertCircle } from "lucide-react"
import { useTranslation } from "react-i18next"
import type { FallbackProps } from "react-error-boundary"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"

export const ActivitiesError = ({ resetErrorBoundary }: FallbackProps) => {
  const { t } = useTranslation("activity")

  return (
    <Alert variant="destructive">
      <AlertCircle />
      <AlertTitle>{t("errors.load")}</AlertTitle>
      <AlertDescription>
        <Button variant="outline" size="sm" onClick={resetErrorBoundary}>
          {t("actions.retry")}
        </Button>
      </AlertDescription>
    </Alert>
  )
}
EOF

cat > src/pages/portfolio/components/activities-content.tsx <<'EOF'
import { useSuspenseQuery } from "@tanstack/react-query"
import { Inbox } from "lucide-react"
import { useTranslation } from "react-i18next"
import { activityQueries } from "@/api/activity"
import { Alert, AlertTitle } from "@/components/ui/alert"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import { ActivityRow } from "./activity-row"

export const ActivitiesContent = () => {
  const { t } = useTranslation("activity")
  const { data, isRefetchError } = useSuspenseQuery(activityQueries.list({}))

  if (data.items.length === 0) {
    return (
      <Empty>
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <Inbox />
          </EmptyMedia>
          <EmptyTitle>{t("empty.title")}</EmptyTitle>
          <EmptyDescription>{t("empty.description")}</EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  return (
    <div className="flex flex-col gap-3">
      {isRefetchError && (
        <Alert variant="destructive">
          <AlertTitle>{t("errors.refetch")}</AlertTitle>
        </Alert>
      )}
      <ul className="flex flex-col divide-y">
        {data.items.map((transaction) => (
          <ActivityRow key={transaction.id} transaction={transaction} />
        ))}
      </ul>
    </div>
  )
}
EOF

cat > src/pages/portfolio/components/activities-list.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { QueryBoundary } from "@/components/query-boundary"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ActivitiesContent } from "./activities-content"
import { ActivitiesError } from "./activities-error"
import { ActivitiesSkeleton } from "./activities-skeleton"

export const ActivitiesList = () => {
  const { t } = useTranslation("activity")

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t("title")}</CardTitle>
      </CardHeader>
      <CardContent>
        <QueryBoundary fallback={<ActivitiesSkeleton />} errorFallback={ActivitiesError}>
          <ActivitiesContent />
        </QueryBoundary>
      </CardContent>
    </Card>
  )
}
EOF

cat > src/pages/portfolio/constants.ts <<'EOF'
export const SKELETON_ROWS = 3
EOF

cat > src/pages/portfolio/portfolio-page.tsx <<'EOF'
import { useTranslation } from "react-i18next"
import { ActivitiesList } from "./components/activities-list"

const PortfolioPage = () => {
  const { t } = useTranslation("portfolio")

  return (
    <main className="mx-auto flex max-w-5xl flex-col gap-6 p-6">
      <h1 className="text-2xl font-semibold">{t("title")}</h1>
      <ActivitiesList />
    </main>
  )
}

export default PortfolioPage
EOF

cat > src/pages/portfolio/index.ts <<'EOF'
export { default } from "./portfolio-page"
EOF

git add -A
git commit -q -m "base: portfolio page, activity list, shadcn primitives and shared query client"
