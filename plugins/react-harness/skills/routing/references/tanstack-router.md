# TanStack Router with the query cache

How is a TanStack Router route wired in this stack: the router context with the query client, `validateSearch`, `loaderDeps`, a loader that fills the query cache, typed params and links, pending and error, preloading and `beforeLoad`?

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`, `[ENTITY]`) with real names. Shown for file-based routes (`createFileRoute`); a code-based route tree takes the same options. The filters hook is in [search-params.md](search-params.md).

## The query client is router context

```tsx
interface IRouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<IRouterContext>()({
  component: AppLayout,
})
```

```tsx
export const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreload: "intent",
  defaultPreloadStaleTime: 0,
})

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router
  }
}
```

Every `beforeLoad` and `loader` receives `context.queryClient`, the same client
`QueryClientProvider` holds; no route imports a client of its own. `Register` types every
`Link`, `navigate` and `useSearch` in the app against this router.

`defaultPreload: "intent"` runs a route's loader when the user hovers or focuses its link, so
the manual prefetch-on-intent of `tanstack-query` is not written by hand here.
`defaultPreloadStaleTime: 0` hands freshness to the query cache: the router always runs the
loader, and `ensureQueryData` decides whether a request goes out.

## A list route

```tsx
export const Route = createFileRoute("/[entity]s/")({
  validateSearch: [entity]FiltersSchema,
  search: { middlewares: [stripSearchParams([ENTITY]_FILTER_DEFAULTS)] },
  loaderDeps: ({ search: { status, page, tags, archived } }) => ({ status, page, tags, archived }),
  loader: async ({ context: { queryClient }, deps }) => {
    await queryClient.ensureQueryData([entity]Queries.list(deps))
  },
  pendingComponent: [Entity]ListSkeleton,
  errorComponent: [Entity]RouteError,
  component: [Entity]ListPage,
})
```

- `validateSearch` takes the screen's Zod 4 schema directly (Standard Schema). With Zod 3 it
  is `zodValidator([entity]FiltersSchema)` from `@tanstack/zod-adapter`, and a fallback is
  `fallback(z.number(), 1)` instead of `.catch(1)`, so the field stays optional in `Link`'s
  types. `.catch()` keeps a bad value from reaching the screen; `.default()` would instead
  throw into `errorComponent` and make `search` required on every link.
- `loaderDeps` returns the fields the query key uses, never `({ search }) => search`: a param
  the loader does not read (an open dialog, a tab) would otherwise reload the route.
- The loader awaits `ensureQueryData` and returns nothing, so the router keeps no second copy.
  In a TanStack Query version whose `QueryClient` has `query()`, the call is
  `queryClient.query({ ...[entity]Queries.list(deps), staleTime: "static" })` (`tanstack-query`).

```tsx
const [Entity]ListPage = () => {
  const deps = Route.useLoaderDeps()
  const { data } = useSuspenseQuery([entity]Queries.list(deps))

  return <[Entity]List items={data.items} />
}
```

The component builds its key from `useLoaderDeps()`, the loader's own inputs, so both read one
cache entry; `useSuspenseQuery` returns at once with `data` present, and the route's
`pendingComponent` and `errorComponent` own the other states. Components that change the
filters use `use[Entity]Filters()` from [search-params.md](search-params.md).

## A detail route: typed params

```tsx
export const Route = createFileRoute("/[entity]s/$id")({
  loader: async ({ context: { queryClient }, params: { id } }) => {
    await queryClient.ensureQueryData([entity]Queries.byId(id))
  },
  errorComponent: [Entity]RouteError,
  component: [Entity]DetailPage,
})

const [Entity]DetailPage = () => {
  const { id } = Route.useParams()
  const { data: [entity] } = useSuspenseQuery([entity]Queries.byId(id))

  return <[Entity]Detail [entity]={[entity]} />
}
```

`$id` is typed `string` from the path, so nothing is cast. A param that must be a number or a
known set goes through the route's `params: { parse, stringify }` with the same schema style
as the search, once.

Links are typed against the route tree: `<Link to="/[entity]s/$id" params={{ id }}>` fails to
compile on a wrong path or a missing param, so TanStack Router needs no `paths` object.
Changing search from a link uses the same updater as the hook:
`<Link to="." search={(previous) => ({ ...previous, page: previous.page + 1 })}>`.

## Pending and error

`pendingComponent` shows after `pendingMs` (1 s by default) and stays at least `pendingMinMs`
(500 ms), so a fast loader never flashes a skeleton. A nested route has its own
`pendingComponent`; the parent's layout stays on screen while a child loads.

```tsx
const [Entity]RouteError = ({ error }: ErrorComponentProps) => {
  const router = useRouter()
  const { reset } = useQueryErrorResetBoundary()

  useEffect(() => {
    reset()
  }, [reset])

  return (
    <ErrorState
      title={t(describe(error).messageKey)}
      action={<Button onClick={() => router.invalidate()}>{t("actions.retry")}</Button>}
    />
  )
}
```

`reset()` clears the query error flag when the error UI mounts, so the retried render fetches
instead of re-throwing the cached error; this effect syncs with the query cache, which is what
an effect is for (`react`). `router.invalidate()` re-runs the loaders and resets the error
boundary. `describe` and its keys are `error-handling`'s.

## An auth guard in `beforeLoad`

```tsx
export const Route = createFileRoute("/_authenticated")({
  beforeLoad: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQueries.me())

    if (!session) {
      throw redirect({ to: "/login", search: { redirect: location.href } })
    }
  },
})
```

`beforeLoad` runs before every child's loader, so a protected screen never renders or fetches
for a signed-out user. The session lives in the query cache like any other server data; a
component effect that checks it and calls `navigate` renders the protected screen first.
