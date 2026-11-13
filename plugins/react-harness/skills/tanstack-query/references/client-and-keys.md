# The shared client and query keys

What does the project's shared `QueryClient` already decide, what belongs in a query key, which part of key correctness the lint rule checks, and how the key factory makes invalidation work?

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `[ENTITY]` for constants, `I[Entity]` type identifiers) with real names. Real infrastructure (`createQueryKeyFactory`) keeps its real name.

## What the shared client already decides

Open the project's shared `QueryClient` before writing the first query. It typically already sets `staleTime`, `gcTime`, `refetchOnWindowFocus`, `refetchOnReconnect`, a `retry` predicate that gives up on 4xx, and `QueryCache`/`MutationCache` `onError` handlers.

- A default restated per query is noise: `staleTime: 1000 * 60 * 5` on a query when the client already says that is a line the next reader has to diff against the client. The same goes for `retry: false` on a query whose only failure worth stopping on is a 4xx the predicate already gives up on.
- Override a default only when this query's data really is more or less volatile than the rest, and give the reason in a `// !` note on that line.
- Auth belongs to the cache handlers, not to a hook. When the client's `QueryCache`/`MutationCache` `onError` handles 401 and token refresh, a local `onError` that re-handles it starts a second refresh flow that races the first.
- `mutations: { retry: false }` is deliberate: a retried POST is a duplicate write.
- A background error toast lives in the shared `QueryCache` `onError`: it fires when `query.state.data !== undefined` (the user still sees the old data) and takes its text from the query's `meta.errorMessage`, typed through `Register`'s `queryMeta`. A failed first load renders the screen's error state, not a toast. The handler's code, with the tracker call beside it, is in the `error-handling` skill, `references/reporting.md`.

## Every input is in the key

The key is the cache identity. Get it wrong and the cache either serves data fetched for other inputs or loses the entry entirely. Every input the response depends on is in the key: id, filters, pagination, sort, locale. A parameter the `queryFn` uses and the key omits is a cache bug, not a style issue.

## The half the linter owns

Where `@tanstack/eslint-plugin-query` is enabled (`flat/recommended`), `exhaustive-deps` errors on a variable the `queryFn` closes over and the key omits, and it resolves through the key factory: `keys.lists()` with `queryFn: () => api.getList(filters)` is a lint error, `keys.list(filters)` passes. Hand-auditing key completeness there, or spending a review comment on it, duplicates the linter.

The rule only looks at an inline function. Given a bare reference, it bails out and checks nothing:

```typescript
queryFn: () => [entity]Api.getMe(),
```

```typescript
queryFn: [entity]Api.getMe,
```

The first is checked; the rule skips the whole options object for the second. Write the arrow form even for a fetcher that takes no arguments: it keeps the check armed for the day someone adds a parameter, and the bare reference is an opt-out that reads as brevity.

Also machine-owned and not worth reviewing by hand: `stable-query-client`, `no-unstable-deps`, `no-void-query-fn`, `no-rest-destructuring`, and the `queryOptions` / infinite / mutation property-order rules.

## What no rule can see

- Whether the key came from the factory at all. A hand-written `["user", id]` at a call site passes every rule and is invisible to `keys.all()`.
- `lists()` against `list(filters)`: which one an invalidation should use, and whether the unfiltered parent key exists. An infinite query has its own entry (`infinite(filters)`): it stores pages in a different shape from the plain list, so sharing `list(filters)`'s key merges two incompatible cache entries.
- The breadth of an invalidation. Nothing checks that a single-item edit didn't sweep the entity.
- Serializability. A fresh object literal in a key is fine, since TanStack hashes deterministically, but a `Date`, a `Map`, a class instance or a function is not. Normalize to a primitive or a plain object first.
- One `queryFn`, one key. Two endpoints sharing a key is the same bug twice, and no linter compares two files.
- `lists()` used as a read key. It is the parent for invalidation: a query keyed `lists()` while its `queryFn` reads `filters` shares one entry across every filter, and the screen shows the last filter's results. The lint rule catches it only where the `queryFn` is inline.
- Mutations. The plugin does no key analysis on them.

## What the factory guarantees

`createQueryKeyFactory(entity, (all) => ({ ... }))` hands the callback an `all` function and merges it into the result. Three consequences decide whether invalidation works:

- Every entry is a function, and it is called: `keys.all()`, `keys.me()`, not `keys.all`. Passing the function itself into `queryKey` hashes the function, not the key.
- Every key spreads `all()` as its first element. That shared prefix is the only reason `invalidateQueries({ queryKey: keys.all() })` sweeps the entity; a key built without it is invisible to the sweep and goes stale forever. The callback receives `all` so nobody rebuilds the prefix by hand.
- A filtered key needs an unfiltered parent. Matching is by array prefix, so `[entity, "list", filters]` cannot be invalidated as a group by its own factory method; the workaround of passing a filters object leans on TanStack's partial-object matching, which breaks the day someone adds `exact: true`. Give the factory both:

```typescript
export const [entity]Keys = createQueryKeyFactory([ENTITY]_ENTITY, (all) => ({
  lists: () => [...all(), [ENTITY]_QUERY_KEYS.LIST] as const,
  list: (filters: I[Entity]Filters) => [...all(), [ENTITY]_QUERY_KEYS.LIST, filters] as const,
  infinite: (filters: I[Entity]Filters) => [...all(), [ENTITY]_QUERY_KEYS.INFINITE, filters] as const,
  byId: (id: string) => [...all(), id] as const,
}))
```

`lists()` invalidates every filter combination by prefix; `list(filters)` addresses one; `infinite(filters)` is its own entry so the paginated cache never collides with the plain list. `lists()` does not reach it, since matching is by prefix and its second element is `INFINITE`, not `LIST`: an edit that changes what an infinite list shows invalidates its key too, or the factory gains an unfiltered `infinites()` parent beside `lists()`. The same holds for any other parameterized key.

Breadth, narrowest first: `byId(id)` → `list(filters)` → `lists()` → `all()`. Pick the narrowest that covers what changed.
