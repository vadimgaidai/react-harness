# Query Key Factory & TanStack Query

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.
> This file is the **shape**: where the code lives, what it is named, how the key factory is called. The **policy** — what belongs in a key, when to use `enabled`/`select`/`keepPreviousData`, how narrowly to invalidate — is the `tanstack-query` skill (`react-harness` plugin). Load it too when you are writing the data layer.

### The shared client (`src/shared/lib/react-query/client.ts`)

One `QueryClient`, instantiated once, imported by `app/` to build the provider. Its defaults
(`staleTime`, `retry`, `QueryCache`/`MutationCache` handlers) are the `tanstack-query` skill's
policy; this file only says where it lives.

### The factory itself (`src/shared/lib/react-query/query-key-factory.ts`)

```typescript
type TQueryKeyFactory<T extends Record<string, (...args: never[]) => readonly unknown[]>> = {
  [K in keyof T]: T[K]
} & {
  all: () => readonly [string]
}

export const createQueryKeyFactory = <
  T extends Record<string, (...args: never[]) => readonly unknown[]>,
>(
  entity: string,
  keys: (all: () => readonly [string]) => T
): TQueryKeyFactory<T> => {
  const all = () => [entity] as const
  return { all, ...keys(all) }
}
```

### Defining keys + queryOptions

Defined inside the entity (`entities/[entity]/api/[entity].queries.ts`). Constants live in `model/constants.ts` to keep string segments out of the api layer.

```typescript
// entities/[entity]/api/[entity].queries.ts
export const [entity]Keys = createQueryKeyFactory([ENTITY]_ENTITY, (all) => ({
  byId: (id: string) => [...all(), id] as const,
  lists: () => [...all(), [ENTITY]_QUERY_KEYS.LIST] as const,
  list: (filters: { status?: T[Entity]Status }) => [...all(), [ENTITY]_QUERY_KEYS.LIST, filters] as const,
}))

export const [entity]Queries = {
  byId: (id: string) =>
    queryOptions({ queryKey: [entity]Keys.byId(id), queryFn: () => [entity]Api.getById(id) }),
  list: (filters: { status?: T[Entity]Status }) =>
    queryOptions({ queryKey: [entity]Keys.list(filters), queryFn: () => [entity]Api.getList(filters) }),
}
```

### Consuming a query in a component

```tsx
import { useQuery } from "@tanstack/react-query"
import { [entity]Queries } from "@/entities/[entity]"

export const [Entity]Badge = ({ id }: { id: string }) => {
  const { data: item, isPending } = useQuery([entity]Queries.byId(id))
  if (isPending || !item) return null
  return <span>{item.name}</span>
}
```

### Invalidation patterns

Matching is by array prefix, narrowest first:

```typescript
// One item
queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })

// One filter combination
queryClient.invalidateQueries({ queryKey: [entity]Keys.list({ status }) })

// Every list, whatever its filters — this is why `lists()` exists alongside `list()`
queryClient.invalidateQueries({ queryKey: [entity]Keys.lists() })

// Every [entity]-scoped query
queryClient.invalidateQueries({ queryKey: [entity]Keys.all() })
```

Every key spreads `all()` as its first element — that shared prefix is what makes the last line work. A key built without it is invisible to the entity sweep. Every factory entry is a function, including the zero-argument ones: `[entity]Keys.all()`, never `[entity]Keys.all`.

