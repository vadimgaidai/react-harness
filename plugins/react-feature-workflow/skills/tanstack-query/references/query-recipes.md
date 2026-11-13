# Query Recipes

How is a read written and rendered: which state flag drives which render, and how do dependent, derived, parallel, paginated, infinite, cancellable and prefetched reads look?

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names. Real infrastructure (`queryClient`, `createQueryKeyFactory`) keeps its real name.
>
> Where these files live and how they are named: the structure skill. What belongs inside them: the `tanstack-query` skill.

## Where a read is declared

Queries are declared as `queryOptions({ ... })` objects in the entity and consumed with `useSuspenseQuery([entity]Queries.x(...))` inside a `QueryBoundary`, or with `useQuery` where a fallback is wrong (`tanstack-query` §Reads). The component picks the hook; it never re-declares the key or the fetcher, so the key cannot drift between two call sites. The response type comes from the module's types, which come from the contract; a guessed shape is a bug the compiler cannot see.

## Suspense read — the default

The boundary owns loading and the failed first load, so the reading component renders only
what the data says: empty, or the content with a refetch alert over it.

```tsx
export const [Entity]Section = () => {
  const [status, setStatus] = useState<T[Entity]Status>(DEFAULT_STATUS)
  const [isSwitching, startTransition] = useTransition()

  const selectStatus = (next: T[Entity]Status) => {
    startTransition(() => {
      setStatus(next)
    })
  }

  return (
    <section className={cn("flex flex-col gap-4", isSwitching && "opacity-60")}>
      <[Entity]StatusFilter value={status} onChange={selectStatus} />
      <QueryBoundary fallback={<[Entity]ListSkeleton />} errorFallback={[Entity]ListError}>
        <[Entity]List status={status} />
      </QueryBoundary>
    </section>
  )
}
```

```tsx
export const [Entity]List = ({ status }: I[Entity]ListProps) => {
  const { t } = useTranslation()
  const { data, isRefetchError } = useSuspenseQuery([entity]Queries.list({ status }))

  if (data.items.length === 0) {
    return <[Entity]Empty />
  }

  return (
    <>
      {isRefetchError && <Alert variant="destructive">{t("[entity].refetchFailed")}</Alert>}
      <ul>{data.items.map((item) => <[Entity]Row key={item.id} item={item} />)}</ul>
    </>
  )
}
```

- `status` is in the key, so a new status is a new cache entry and suspends. The setter in
  `startTransition` keeps the current list on screen, dimmed by the transition's pending flag,
  until the next one is ready; set directly, the list is replaced by the skeleton on every switch.
- `useSuspenseQuery` takes neither `enabled` nor `placeholderData`: a disabled or placeholder
  state is what the `useQuery` reads below are for.
- `QueryBoundary` and its retry are in the `react` skill, references/code-splitting.md.

## The state flags

- `isPending`: no data yet (the v5 name). `isLoading` is `isPending && isFetching`, and is not what a disabled query wants.
- `isFetching`: a request is in flight, including a background refetch over data already shown. It drives a subtle indicator, never the main skeleton.
- `data` is `undefined` while pending. Narrow on the state instead of `data!` or `data?.x ?? fallback`.
- Loading, empty and error are three different renders. A list that returns `null` on an empty array is a bug; empty needs its own copy.
- `isLoadingError`: the first load failed and there is nothing to show. `isRefetchError`: a background refetch failed and `data` still holds the last good value; render it with an inline alert, never blank it.
- The v5 types narrow in this order: check `isPending` first (`data` is `undefined`), then `isError` (`error` is set; for `isLoadingError`, `data` is still `undefined`); only after both are false is `data` narrowed to present.
- Under `useQuery` a failed first load renders inline on `isError`; a region that should hand it to a boundary reads with `useSuspenseQuery` instead of setting `throwOnError` by hand.
- In suspense mode the default is `throwOnError: (error, query) => query.state.data === undefined`: a refetch failure over cached data does not reach the boundary, the component keeps rendering and the error sits in `error`. A boundary retry needs `QueryErrorResetBoundary` with `onReset={reset}`, or it re-renders the same cached error; the shape is in the `react` skill, references/code-splitting.md.
- `refetch()` is not invalidation. It re-runs only the observer that called it and ignores every other observer of that key and every other key a mutation would sweep; it is for a user-visible "retry this" action only.

## `useQuery` reads — five states, five renders

Where a read stays on `useQuery` (disabled until its input exists, cancellable, per keystroke,
optional), the same call passes through states that each need their own render, identified by
their own flag — never collapsed into one "loading" or one "error" branch:

| State | Flag | Render |
|---|---|---|
| Initial load | `isPending` | skeleton the shape of the content |
| Disabled (`skipToken`) | `isPending && !isFetching` | the screen's idle state — a prompt, not a skeleton |
| Background refetch over shown data | `isFetching && !isPending` | the existing content, with a subtle indicator |
| Pagination/filter switch | `isPlaceholderData` | the previous page, dimmed, "next" disabled |
| Refetch error over cached data | `isRefetchError` | the cached content, with an inline alert — never blanked |

```tsx
const { data, isPending, isFetching, isPlaceholderData, isRefetchError } = useQuery({
  ...[entity]Queries.list({ scope: filters.scope, page }),
  placeholderData: keepPreviousData,
})

if (!filters.scope) {
  return <EmptyState title={t("[entity].selectScope")} />
}

if (isPending) {
  return <[Entity]ListSkeleton />
}

return (
  <>
    {isRefetchError && <Alert variant="destructive">{t("[entity].refetchFailed")}</Alert>}
    <[Entity]List items={data} className={cn(isPlaceholderData && "opacity-50")} />
    {isFetching && !isPlaceholderData && <Spinner />}
  </>
)
```

A query disabled by `skipToken` is `isPending: true` with no request in flight, so the
missing input is checked first: checked after `isPending`, the disabled screen shows the
skeleton forever. The `list` factory passes `skipToken` as its `queryFn` while `scope` is
missing, as in the dependent query below, and `scope` is in the key because the `queryFn` reads it.

## Dependent query — `skipToken`, never an early return

```tsx
const { data: user } = useQuery(userQueries.me())
const { data: orders, isPending } = useQuery(orderQueries.byUser(user?.id))
```

```typescript
byUser: (userId: string | undefined) =>
  queryOptions({
    queryKey: orderKeys.byUser(userId),
    queryFn: userId ? () => orderApi.getByUser(userId) : skipToken,
  }),
```

Until `userId` exists the query is disabled: `isPending` is `true`, `isFetching` is `false`,
nothing is requested. Inside the truthy branch `userId` is a `string`, so the fetcher gets a
real id with no `as` and no `!` (`typescript` skill). A query disabled by `skipToken` ignores a
manual `refetch()`; where a "retry" button must work on a disabled query, use
`enabled: Boolean(userId)` instead and keep the narrowing inside the fetcher.

Under Suspense there is no disabled state. When the input is itself a suspense read, the
second read takes `user.id` directly and waits for it by nature. When the input comes from the
user (a selected id), the parent renders the reading component only once it exists:
`{selectedId && <[Entity]Details id={selectedId} />}` inside the boundary.

A `if (!user) return null` above the second `useQuery` would break the rules of hooks; an
effect that triggers the fetch, or one that refetches what a key change already refetches,
reimplements the cache badly. The same goes for copying `data` into `useState`: the cache is
the state, and the copy is the derived-state bug in a data-layer costume.

## Deriving from the response — `select`

`list({})` **as a query** is a real cache entry: the unfiltered list. That is a different act from invalidation, where the group key is `lists()` — reading one filter combination and invalidating all of them are not the same call.

Narrowing which re-renders this causes: this component re-renders only when the count changes, not on every change to the list.

```tsx
const { data: activeCount } = useQuery({
  ...[entity]Queries.list({}),
  select: (items) => items.filter((item) => item.status === "active").length,
})
```

`select` re-runs when the data changes or when the `select` function's identity changes between renders. Under the React Compiler an inline `select` that reads a prop is memoized on that prop and stays stable:

```tsx
const { data: filtered } = useQuery({
  ...[entity]Queries.list({}),
  select: (items) => items.filter((item) => item.status === status),
})
```

Without the Compiler, an inline closure is a new function every render and narrows nothing: hoist it to module scope when it reads no props, or wrap it in `useCallback` with the prop as its dependency.

**`select` is not a filter for the server.** If the API can filter, put the filter in the key and let the backend do it — `select` on a 10 000-item payload still downloaded 10 000 items.

## Dynamic parallel queries — `useQueries`

A fixed set is just two hooks. Use `useQueries` only when the number of queries is data-driven:

```tsx
const results = useQueries({
  queries: ids.map((id) => [entity]Queries.byId(id)),
  combine: (queries) => ({
    data: queries.map((query) => query.data).filter(Boolean),
    isPending: queries.some((query) => query.isPending),
  }),
})
```

`combine` runs on the results array and keeps the component from re-rendering on every individual settle. Without it, read `results` directly — don't map it into `useState`. Under Suspense the same call is `useSuspenseQueries`, which starts every query before any suspends.

## Pagination — keep the previous page on screen

```tsx
import { keepPreviousData, useQuery } from "@tanstack/react-query"

const { data, isPlaceholderData } = useQuery({
  ...[entity]Queries.list({ page }),
  placeholderData: keepPreviousData,
})
```

`initialData` is cached as if it were fetched and ages by `staleTime`; `placeholderData` is never written to the cache, so it is the choice unless the complete, authoritative object is already at hand.

`page` is in the key, so each page is cached separately; `keepPreviousData` is what stops the list unmounting into the empty state between pages. Dim the container on `isPlaceholderData` and disable "next" while it is `true`, so a fast clicker can't skip a page that hasn't loaded. Under Suspense the page setter runs in `startTransition` instead and the transition's pending flag does the dimming, as in the Suspense read above.

## Infinite list

The key is `infinite(filters)` — its own entry in the factory, next to `list(filters)` — so the paginated cache never collides with the plain list's. The cursor is not in the key: TanStack stores every page under that one key, and only `filters` belongs there, because changing a filter starts a different list.

```typescript
const FIRST_PAGE: string | null = null

export const [entity]Queries = {
  infinite: (filters: I[Entity]Filters) =>
    infiniteQueryOptions({
      queryKey: [entity]Keys.infinite(filters),
      queryFn: ({ pageParam }) => [entity]Api.getList({ ...filters, cursor: pageParam }),
      initialPageParam: FIRST_PAGE,
      getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    }),
}
```

- `getNextPageParam` returns `undefined` or `null` to mean "no more pages". Any other value is treated as a valid cursor — returning `-1` or `0` from a page-number API leaves `hasNextPage` true forever and fetches page `-1`.
- Guard the trigger on `hasNextPage && !isFetchingNextPage` before calling `fetchNextPage()`, since an intersection observer fires repeatedly while the sentinel is visible.
- The flat list is `data.pages.flatMap((page) => page.items)`. Derive it in render, or in `select` if it is expensive — never in state.
- On a very long list, cap retention with `maxPages` so the cache doesn't grow without bound; note that a cap makes the list re-fetch when scrolling back up.

## Cancellation

Pass the signal through when the request can be superseded — a search-as-you-type, or a page the user navigates away from mid-flight:

```typescript
queryFn: ({ signal }) => [entity]Api.getList(filters, { signal })
```

`ky`, `axios` and `fetch` all take `{ signal }` directly. Without it the aborted response still arrives and still resolves. Cancellation does not work under Suspense, so a read that must be cancelled stays on `useQuery`.

## Prefetch on intent

```tsx
const queryClient = useQueryClient()

const prefetch = (id: string) => queryClient.prefetchQuery([entity]Queries.byId(id))

<Link to={paths.[entity].details(id)} onMouseEnter={() => prefetch(id)} onFocus={() => prefetch(id)}>
```

Prefetch on intent, `onMouseEnter` and `onFocus` on the trigger, for the one or two navigations the user is visibly about to make; prefetching a whole list on mount is just fetching, later. Pair it with the lazy-route preload from the `react` skill, so the chunk and its data are in flight together.

In a v5 release whose `QueryClient` has `query()`, `prefetchQuery` is deprecated; the same call is `queryClient.query([entity]Queries.byId(id)).catch(noop)`, which discards the error the same way. In a TanStack Router project the router's `defaultPreload: "intent"` runs the destination's loader on hover and focus, so this is not written by hand (`routing`, references/tanstack-router.md).

Spreading the same options object is the point — the prefetched key is the key the destination will read. `prefetchQuery` respects `staleTime`, so a second hover is free; it never throws, so it needs no error handling.
