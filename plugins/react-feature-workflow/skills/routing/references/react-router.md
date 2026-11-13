# React Router with the query cache

How is a React Router route wired in this stack: the router, a loader that fills the TanStack Query cache, route params, pending and error UI, an auth guard, and what changes in declarative mode?

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`) with real names. Read the version in `package.json` once: v8 imports from `react-router` and `react-router/dom`, v7 from `react-router`, v6 from `react-router-dom`. The filters hook is in [search-params.md](search-params.md).

## Data mode or declarative mode

Routes passed to `createBrowserRouter` and rendered with `RouterProvider` are data mode:
loaders, `errorElement` and `useNavigation` exist. `<BrowserRouter>` with `<Routes>` is
declarative mode: none of them do, and the last section applies. A route `action` and
`<Form>` stay unused in both: a write is a TanStack Query mutation behind a React Hook Form
submit, so the cache stays the one owner of server data.

## The router gets the query client through a loader factory

```tsx
export const createAppRouter = (queryClient: QueryClient) =>
  createBrowserRouter([
    {
      path: paths.root,
      Component: AppLayout,
      children: [
        {
          path: paths.[entity].detailsPattern,
          loader: [entity]DetailLoader(queryClient),
          Component: [Entity]DetailPage,
          errorElement: <[Entity]RouteError />,
        },
      ],
    },
  ])
```

The app creates one `QueryClient`, passes it to `QueryClientProvider` and to
`createAppRouter`; a loader never imports a client of its own, which would be a second cache.
Route paths come from one `paths` object: `detailsPattern` for the route, a builder such as
`paths.[entity].details(id)` for links and `navigate`, so a renamed path changes one line.

## A loader fills the cache and returns nothing to keep

```tsx
export const [entity]RouteParamsSchema = z.object({ id: z.string().min(1) })

export const [entity]DetailLoader =
  (queryClient: QueryClient) =>
  async ({ params }: LoaderFunctionArgs) => {
    const { id } = [entity]RouteParamsSchema.parse(params)

    await queryClient.ensureQueryData([entity]Queries.byId(id))

    return null
  }
```

`ensureQueryData` returns the cached entry when one exists and fetches only when it does not,
into the same cache the component reads. In a TanStack Query version whose `QueryClient` has
`query()`, `ensureQueryData` is deprecated and the same call is
`queryClient.query({ ...[entity]Queries.byId(id), staleTime: "static" })` (`tanstack-query`).
The loader returns `null`, the empty value React Router expects from a loader; a loader that returns the
entity for `useLoaderData()` creates a second copy that the next invalidation leaves behind.

`params` is `Record<string, string | undefined>`; the schema narrows it once, so neither the
loader nor the component writes `params.id as string`. An invalid param throws into the
route's `errorElement`.

```tsx
export const [Entity]DetailPage = () => {
  const { id } = [entity]RouteParamsSchema.parse(useParams())
  const { data: [entity] } = useSuspenseQuery([entity]Queries.byId(id))

  return <[Entity]Detail [entity]={[entity]} />
}
```

The loader already filled the cache, so `useSuspenseQuery` returns at once with `data`
present and typed: no `isPending` branch, no `data?.`. A list route does the same with the
filters read from `request.url` through the screen's schema, `readFilters(new URL(request.url).searchParams)`.

## Pending and error come from the router

```tsx
export const AppLayout = () => {
  const navigation = useNavigation()

  return (
    <>
      {navigation.state === "loading" && <Spinner />}
      <Outlet />
    </>
  )
}
```

`navigation.state` is `"loading"` while any loader runs, whatever started the navigation: a
link, `navigate()`, the Back button. A component that tracks its own `isNavigating` around
`navigate()` drifts from it the first time a navigation starts elsewhere.

```tsx
export const [Entity]RouteError = () => {
  const error = useRouteError()
  const { reset } = useQueryErrorResetBoundary()
  const revalidator = useRevalidator()

  const retry = () => {
    reset()
    revalidator.revalidate()
  }

  return (
    <ErrorState
      title={t(describe(error).messageKey)}
      action={<Button onClick={retry}>{t("actions.retry")}</Button>}
    />
  )
}
```

`errorElement` catches a loader that threw and a `useSuspenseQuery` that threw while
rendering. The retry clears the query error flag, so the next render fetches instead of
re-throwing the cached error, and re-runs the loaders. `describe` and its keys are
`error-handling`'s.

## Nested routes keep their own boundary

```tsx
{
  path: paths.[entity].rootPattern,
  Component: [Entity]Layout,
  children: [
    { index: true, Component: [Entity]Overview },
    { path: "activity", loader: activityLoader(queryClient), Component: [Entity]Activity },
  ],
}
```

`[Entity]Layout` renders its chrome once and an `<Outlet />` for the child; only the child's
region waits for `activityLoader`, and switching between `Overview` and `Activity` never blanks
the layout above it.

## An auth guard before the route loads

React Router v8 runs route middleware by default (v7 behind a future flag): the guard reads the
session from the cache and redirects before any child loader runs.

```tsx
export const authMiddleware =
  (queryClient: QueryClient): MiddlewareFunction =>
  async (_args, next) => {
    const session = await queryClient.ensureQueryData(sessionQueries.me())

    if (!session) {
      throw redirect(paths.login)
    }

    return next()
  }
```

The protected parent route takes `middleware: [authMiddleware(queryClient)]`. A component that
checks the session in an effect and calls `navigate` renders the protected screen for a frame
and runs its loaders first.

## Preloading

Data-mode `<Link>` has no data preloading of its own (`prefetch` is framework mode), so a
link the user is about to follow prefetches on intent with the query options its route uses
(`tanstack-query`, prefetch on intent), beside the lazy-route chunk preload (`react`).

## Declarative mode

No loaders: the component reads `useQuery` with the filters hook and renders the query's states
itself (`tanstack-query` §States), with an error boundary around the route element
(`react`, code splitting). Params are parsed through the same schema, and paths come from the
same `paths` object.
