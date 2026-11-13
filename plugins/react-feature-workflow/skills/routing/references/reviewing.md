# Reviewing: routing

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- a filter, sort or page number not restored from the URL on load, or URL state copied into `useState` once instead of read on every render
- a search or route param read without the screen's schema: `searchParams.get("x") as T`, `params.id as string`, a manual `Number(...)` per call site
- updating one search param that drops the others instead of merging (`setSearchParams({ … })` with an object, a `search` object instead of an updater)
- a filters setter that takes the whole state instead of a patch (`code-shape`), that does not reset `page` when a filter changes, or that writes a default value into the URL instead of deleting it (`references/search-params.md`)
- a loader whose data the component reads with `useLoaderData` beside the query cache, or a loader that fetches outside the cache
- a component on a loader-backed route that reads the query with `useQuery` and an `isPending` branch where `useSuspenseQuery` was meant, or builds its key from other inputs than the loader's
- `loaderDeps` returning the whole search object
- a second `QueryClient` imported in a loader instead of the router context or the loader factory
- a navigation pending or error flag kept in component state instead of the router's own mechanism, or an error UI whose retry does not reset the query error
- an auth check in a component effect that calls `navigate` instead of `beforeLoad` or middleware
- a router `action` or `<Form>` writing server data beside the mutations
- a path built as a string at the call site instead of the `paths` object (React Router) or a typed `to` with `params` (TanStack Router)
- a child route's fetch blanking the parent's already-rendered layout
