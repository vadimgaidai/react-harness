# Reviewing: tanstack-query

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- a region read on `useQuery` with `isPending`/`isError` branches where none of the reasons for it holds (disabled until input, cancellable, per keystroke, optional data), so a `useSuspenseQuery` inside a `QueryBoundary` was meant
- a key-changing switch under Suspense set without `startTransition`, so the list is replaced by the skeleton on every switch
- two sibling `useSuspenseQuery` reads in one boundary that load one after the other, where `useSuspenseQueries` or a prefetch was meant
- a key missing an input the `queryFn` closes over, found at a hand-written call site the lint rule's bare-reference gap let through
- a per-query `retry`, `staleTime` or other option that repeats what the shared `QueryClient` already sets
- query data mirrored into `useState`, or a fetch inside `useEffect`
- an invalidation broader than the change — a full `keys.all()` sweep on an edit, or narrower than it — a create/delete that only hits `byId`
- an infinite query and the plain list sharing one key
- `refetch()` used where an invalidation was meant
- a disabled query replaced by an early `return` or a conditional hook, or a dependent query that casts its input (`id as string`, `id!`) where `skipToken` was meant
- an invalidation in `onSuccess`/`onSettled` that is not returned, so the mutation settles before the fresh data lands
- an optimistic update applied twice (`onMutate` and again on the server response), or a snapshot rollback on an action that can fire again before it settles, where invalidating on the last settle (`isMutating`) was meant
- `setQueryData` writing a partial or client-assembled object
- a local `onError` re-handling what the shared `QueryCache`/`MutationCache` handler already does
- a shared mutation option overridden without calling the original callback
- a query missing `signal` on a request that can be superseded
