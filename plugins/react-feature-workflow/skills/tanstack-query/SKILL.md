---
name: tanstack-query
description: TanStack Query v5 rules for a client-rendered SPA — what the shared QueryClient already decides (retry, staleTime, onError), what goes in a query key, enabled/skipToken/select/useQueries/placeholderData, isPending/isFetching states, and how a mutation touches the cache. Use whenever a task writes or reviews useQuery, useMutation, useInfiniteQuery, useSuspenseQuery, queryOptions, ensureQueryData or queryClient.query, a query key or key factory, invalidateQueries, setQueryData, an optimistic update, pagination, prefetching, a retry or staleTime setting, or a fetch inside useEffect.
---

# TanStack Query v5

TanStack Query v5 in a client-rendered SPA: no `dehydrate`/`hydrate`, no `HydrationBoundary`, no per-request client. Check `package.json` once in the session, since a v4 project reads `isLoading`/`cacheTime`/`useErrorBoundary` and these rules do not fit it; in a v5 release whose `QueryClient` has `query()`, `ensureQueryData`, `fetchQuery` and `prefetchQuery` are deprecated in its favour (`query({ ...options, staleTime: "static" })`, `query(options)`, `query(options).catch(noop)`). This skill owns what goes inside a query or a mutation; where the client, query and mutation files live and which layer may invalidate which is the structure skill loaded in this project.

### Shared client

- Open the shared `QueryClient` before the first query; a per-query `staleTime`, `gcTime`, `retry` or `refetchOn*` that repeats it is noise.
- Override a default only for data that really is more or less volatile, with the reason in a `// !` note on that line.
- No local `onError` for what the `QueryCache`/`MutationCache` handlers already do (401, token refresh): two refresh flows race.
- `mutations: { retry: false }` stays: a retried POST is a duplicate write.
- A background refetch error toasts from the shared `QueryCache` `onError`, only when the query already has data, with the text from the query's `meta.errorMessage`; reporting to the tracker is `error-handling`.

### Keys

- Every input the `queryFn` reads is in the key: id, filters, page, sort, locale.
- Keys come from the entity's factory and are called (`keys.byId(id)`, `keys.all()`), never a hand-written array at a call site.
- `queryFn` is always an arrow (`() => [entity]Api.getMe()`), since the lint rule skips a bare reference.
- A filtered key has an unfiltered parent (`lists()` beside `list(filters)`); an infinite query has its own `infinite(filters)`.
- Key values are primitives or plain objects, never a `Date`, `Map`, class instance or function; one `queryFn`, one key.

### Reads

- Declare `queryOptions` in the entity; the component never re-declares the key or the fetcher, and the response type comes from the contract.
- A region reads with `useSuspenseQuery([entity]Queries.x(...))` inside a `QueryBoundary` (`Suspense`, an error boundary and `QueryErrorResetBoundary` in one component, `react` references/code-splitting.md), so `data` is present and the boundary owns loading and the failed first load; a route whose loader filled the cache reads the same way and the route owns those states (`routing`).
- `useQuery` with inline states stays where a fallback is wrong, and the choice names which: a read disabled until its input exists, a request cancelled by `signal` (cancellation does not work under Suspense), a read refetched per keystroke, or data the screen renders without.
- A switch that changes the key (filter, sort, page, range) runs its setter in `startTransition`, so the shown data stays while the next key loads; under `useQuery` the same is `placeholderData: keepPreviousData`.
- Suspense reads that load together start together, through `useSuspenseQueries` or a prefetch above the boundary: React 19 does not render the siblings of a suspended component, so two sibling `useSuspenseQuery` calls fetch one after the other.
- A dependent read renders its reading component only once the input exists; under `useQuery` it passes `skipToken` as its `queryFn` until then, so the type narrows without a cast; `enabled` only where a manual `refetch()` must still work.
- Derived value → `select` (the Compiler keeps an inline one stable); a data-driven number of queries → `useQueries`, `useSuspenseQueries` under Suspense.
- `placeholderData` over `initialData` unless the complete object is at hand.
- Never copy query data into `useState`, never fetch or refetch inside `useEffect`.
- Pass `signal` to a request that can be superseded, which keeps that read on `useQuery`.
- Prefetch on intent (`onMouseEnter`, `onFocus`) with the same options object the destination reads, beside the lazy-route preload; never a whole list on mount; TanStack Router's `defaultPreload: "intent"` does it through the route's loader.

### States

- Loading, empty and error are three renders: under Suspense the boundary's skeleton fallback, the component's own empty branch, and the boundary's error fallback with a retry; under `useQuery` `isPending` → skeleton and `isError` → inline error, narrowed on the state, never `data!`.
- A refetch error over cached data never reaches the boundary (Suspense throws only when there is no data): the data stays on screen with an inline alert on `isRefetchError`; `isFetching` drives a subtle indicator under either hook.
- `refetch()` is for a user's "retry this", never in place of `invalidateQueries`.

### Mutations

- Invalidate in `onSuccess`, narrowest first: `byId(id)` → `list(filters)` → `lists()` → `all()`; `all()` only on create and delete; never `invalidateQueries()` without a key; return the invalidation promise, so the mutation stays pending until the fresh data lands.
- `setQueryData` only with the complete object the server returned, and only in the mutation's callbacks.
- Optimistic updates only for cheap, reversible, frequent actions: applied once in `onMutate`, reconciled in `onSettled`; an action that can fire again before it settles skips the rollback and invalidates only when the last one settles (`isMutating({ mutationKey }) === 1`).
- Cache work, navigation, toasts and storage writes go in the hook's `onSuccess`/`onError` or `mutate`'s per-call callbacks, never in an effect on `isSuccess`; `mutateAsync` only where a later step awaits it.
- A callback added over spread shared options calls the original first and awaits or returns it.

## Example

A per-query option that repeats the shared client. The client's `retry` predicate already gives up on 4xx, so a 404 is not retried without the override:

```typescript
queryKey: [entity]Keys.bySlug(slug),
queryFn: () => [entity]Api.getBySlug(slug),
retry: false,
staleTime: 1000 * 60 * 5,
```

```typescript
queryKey: [entity]Keys.bySlug(slug),
queryFn: () => [entity]Api.getBySlug(slug),
```

## References

- [references/client-and-keys.md](references/client-and-keys.md): before the first query in a session, or when choosing a key, adding a factory entry, or deciding what the lint rule already checks.
- [references/query-recipes.md](references/query-recipes.md): when rendering query states, or writing a dependent, derived, parallel, paginated, infinite, cancellable or prefetched read.
- [references/mutation-recipes.md](references/mutation-recipes.md): when choosing invalidation breadth, writing a response into the cache, an optimistic update, concurrent mutations, mutation state read elsewhere, or the follow-up after a mutation.
- Anything none of them covers: current upstream docs via the `context7` MCP server (`/tanstack/query`), since v4 answers still top the search results and v5 renamed a lot.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
