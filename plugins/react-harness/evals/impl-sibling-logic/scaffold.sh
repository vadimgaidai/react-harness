#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/../_fixture/base.sh"

mkdir -p src/api/wallets .planning/activity-note

cat > src/lib/invalidate.ts <<'EOF'
import type { QueryKey } from "@tanstack/react-query"
import { queryClient } from "./query-client"

const LAST_MUTATION = 1

export const invalidateOnSettle = (queryKey: QueryKey) => ({
  onSettled: () => {
    if (queryClient.isMutating() > LAST_MUTATION) {
      return
    }
    return queryClient.invalidateQueries({ queryKey })
  },
})
EOF

cat > src/locales/en/wallets.json <<'EOF'
{
  "toast": { "renamed": "Wallet renamed", "archived": "Wallet archived", "restored": "Wallet restored", "defaultSet": "Default wallet changed" }
}
EOF

cat > src/api/wallets/types.ts <<'EOF'
export interface IWallet {
  id: string
  name: string
  address: string
  isArchived: boolean
}

export interface IWalletsListResponse {
  items: IWallet[]
  total: number
}

export interface IRenameWalletInput {
  id: string
  name: string
}
EOF

cat > src/api/wallets/keys.ts <<'EOF'
import { createQueryKeyFactory } from "../../lib/query-keys"

const WALLET_ENTITY = "wallet"
const WALLET_QUERY_KEYS = { LIST: "list", DETAIL: "detail" } as const

export const walletKeys = createQueryKeyFactory(WALLET_ENTITY, (all) => ({
  lists: () => [...all(), WALLET_QUERY_KEYS.LIST] as const,
  detail: (id: string) => [...all(), WALLET_QUERY_KEYS.DETAIL, id] as const,
}))
EOF

cat > src/api/wallets/api.ts <<'EOF'
import { http } from "../../lib/http"
import type { IRenameWalletInput, IWallet, IWalletsListResponse } from "./types"

export const getWallets = (): Promise<IWalletsListResponse> => {
  return http.get<IWalletsListResponse>("/wallets")
}

export const renameWallet = ({ id, name }: IRenameWalletInput): Promise<IWallet> => {
  return http.patch<IWallet>(`/wallets/${id}`, { name })
}

export const archiveWallet = (id: string): Promise<IWallet> => {
  return http.patch<IWallet>(`/wallets/${id}`, { isArchived: true })
}

export const restoreWallet = (id: string): Promise<IWallet> => {
  return http.patch<IWallet>(`/wallets/${id}`, { isArchived: false })
}

export const setDefaultWallet = (id: string): Promise<IWallet> => {
  return http.patch<IWallet>(`/wallets/${id}`, { isDefault: true })
}
EOF

cat > src/api/wallets/queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import { getWallets } from "./api"
import { walletKeys } from "./keys"

export const walletQueries = {
  list: () =>
    queryOptions({
      queryKey: walletKeys.lists(),
      queryFn: getWallets,
    }),
}
EOF

cat > src/api/wallets/mutations.ts <<'EOF'
import { mutationOptions } from "@tanstack/react-query"
import { invalidateOnSettle } from "../../lib/invalidate"
import { queryClient } from "../../lib/query-client"
import { archiveWallet, renameWallet, restoreWallet, setDefaultWallet } from "./api"
import { walletKeys } from "./keys"
import type { IRenameWalletInput, IWallet, IWalletsListResponse } from "./types"

const WALLET_MUTATION_KEYS = { RENAME: "rename", ARCHIVE: "archive", RESTORE: "restore", SET_DEFAULT: "set-default" } as const

const replaceWallet = (wallet: IWallet) => {
  queryClient.setQueryData<IWalletsListResponse>(walletKeys.lists(), (current) => {
    if (!current) {
      return current
    }
    return {
      ...current,
      items: current.items.map((item) => (item.id === wallet.id ? wallet : item)),
    }
  })
}

export const walletMutations = {
  rename: () =>
    mutationOptions({
      mutationKey: [...walletKeys.all(), WALLET_MUTATION_KEYS.RENAME],
      mutationFn: (input: IRenameWalletInput) => renameWallet(input),
      meta: { successKey: "wallets:toast.renamed" },
      onSuccess: (wallet) => {
        replaceWallet(wallet)
      },
      ...invalidateOnSettle(walletKeys.lists()),
    }),

  archive: () =>
    mutationOptions({
      mutationKey: [...walletKeys.all(), WALLET_MUTATION_KEYS.ARCHIVE],
      mutationFn: (id: string) => archiveWallet(id),
      meta: { successKey: "wallets:toast.archived" },
      onSuccess: (wallet) => {
        replaceWallet(wallet)
      },
      ...invalidateOnSettle(walletKeys.lists()),
    }),

  restore: () =>
    mutationOptions({
      mutationKey: [...walletKeys.all(), WALLET_MUTATION_KEYS.RESTORE],
      mutationFn: (id: string) => restoreWallet(id),
      meta: { successKey: "wallets:toast.restored" },
      onSuccess: (wallet) => {
        replaceWallet(wallet)
      },
      ...invalidateOnSettle(walletKeys.lists()),
    }),

  setDefault: () =>
    mutationOptions({
      mutationKey: [...walletKeys.all(), WALLET_MUTATION_KEYS.SET_DEFAULT],
      mutationFn: (id: string) => setDefaultWallet(id),
      meta: { successKey: "wallets:toast.defaultSet" },
      onSuccess: (wallet) => {
        replaceWallet(wallet)
      },
      ...invalidateOnSettle(walletKeys.lists()),
    }),
}
EOF

cat > src/api/wallets/index.ts <<'EOF'
export { walletQueries } from "./queries"
export { walletMutations } from "./mutations"
export { walletKeys } from "./keys"
export type { IRenameWalletInput, IWallet, IWalletsListResponse } from "./types"
EOF

cat > .planning/activity-note/SPEC.md <<'EOF'
# Activity note

A user can attach a short note to one activity transaction.

## Rules

- R-1: Saving a note sends `PATCH /activities/{id}` with `{ note }`.
- R-2: After a save the activity list shows the new note without a reload.
- R-3: A successful save shows the toast "Note saved".

## Acceptance criteria

- AC-1: `activityMutations.updateNote` exists and is exported from `src/api/activity`.
- AC-2: After a successful save the activity list query is refreshed.
- AC-3: The success toast text comes from the `activity` translations.
EOF

cat > .planning/activity-note/contract.md <<'EOF'
# Contract — activity-note

Source: `openapi.json`

## PATCH /activities/{id}

Path: `id` string, required.

Request body (`application/json`): `note` string, required.

Response 200: `ActivityTransaction` — `id` string, `hash` string, `kind` `"send" | "receive" | "swap"`, `amount` number, `symbol` string, `note` string | null, `createdAt` string (date-time). All required except `note`.
EOF

cat > .planning/activity-note/PLAN.md <<'EOF'
# Plan — activity-note

Sibling: `src/api/wallets` — mirror how its mutations are built.

## Modules, in build order

1. `src/api/activity`
   - `api.ts`: `updateActivityNote` for PATCH /activities/{id} (contract.md).
   - `mutations.ts` (new): `activityMutations.updateNote`, serves AC-1, AC-2, AC-3.
   - `index.ts`: export `activityMutations`.
2. `src/locales/en/activity.json`: the toast text for AC-3.

No UI in this unit.
EOF

git add -A
git commit -q -m "wallets module and the activity-note plan"
