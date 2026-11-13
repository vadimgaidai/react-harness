# A component or hook that reads the URL

Answers: how to render a component inside the project's router from a real URL, and how to prove that filters restore from a link, survive Back and never drop another param, in React Router and in TanStack Router?

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`) with real names.
> The router comes from `package.json`; the filters hook is `routing`'s
> (references/search-params.md). The providers are [setup.md](setup.md)'s.

## React Router

```tsx
const renderAt = (url: string) => {
  const queryClient = createTestQueryClient()
  const router = createMemoryRouter(createAppRoutes(queryClient), { initialEntries: [url] })

  render(
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <RouterProvider router={router} />
      </I18nextProvider>
    </QueryClientProvider>
  )

  return router
}
```

`createAppRoutes(queryClient)` is the route array the app hands `createBrowserRouter`, so the
test runs the real loaders, params schema and `errorElement`. A single component that needs
only a route around it uses `createRoutesStub` (v7 and later) with that one route.

## TanStack Router

```tsx
const renderAt = (url: string) => {
  const queryClient = createTestQueryClient()
  const router = createRouter({
    routeTree,
    context: { queryClient },
    history: createMemoryHistory({ initialEntries: [url] }),
  })

  render(
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <RouterProvider router={router} />
      </I18nextProvider>
    </QueryClientProvider>
  )

  return router
}
```

The same route tree and context as the app, so `validateSearch`, `loaderDeps`, the loader and
`errorComponent` all run.

## The URL tests

```tsx
test("restores the filters from a shared link", async () => {
  server.use(
    http.get("/api/[entity]s", ({ request }) => {
      const status = new URL(request.url).searchParams.get("status")
      return HttpResponse.json({ items: status === "open" ? [openItem] : [openItem, closedItem] })
    })
  )

  renderAt("/[entity]s?status=open")

  expect(await screen.findByText(openItem.name)).toBeInTheDocument()
  expect(screen.queryByText(closedItem.name)).not.toBeInTheDocument()
})

test("a filter change keeps the other params and resets the page", async () => {
  const user = userEvent.setup()
  const router = renderAt("/[entity]s?page=3&tab=archive")

  await user.click(await screen.findByRole("button", { name: /open/i }))

  const search = new URLSearchParams(router.state.location.search)
  expect(search.get("status")).toBe("open")
  expect(search.get("tab")).toBe("archive")
  expect(search.has("page")).toBe(false)
})

test("Back restores the previous filter", async () => {
  const user = userEvent.setup()
  const router = renderAt("/[entity]s")

  await user.click(await screen.findByRole("button", { name: /open/i }))
  await act(() => router.navigate(-1))

  expect(await screen.findByText(closedItem.name)).toBeInTheDocument()
})
```

- The first proves the loader and the query key read the URL: the request carries the filter
  and the screen shows its result.
- The second proves the setter merges, resets `page` and keeps a param it does not own. The
  URL is read from the router, not from the hook's state: React Router's
  `router.state.location.search` is the query string; TanStack Router keeps the parsed object
  there and the string in `location.searchStr`.
- The third proves nothing copied the URL into state. Shown for React Router
  (`router.navigate(-1)`); in TanStack Router Back is `router.history.back()`. Either way it
  goes through the router's memory history, never `window.history`.

## The hook alone

```tsx
test("drops a filter equal to its default", () => {
  const { result } = renderHook(() => use[Entity]Filters(), { wrapper: RouterAt("/[entity]s?status=open") })

  act(() => {
    result.current[1]({ status: "all" })
  })

  expect(result.current[0].status).toBe("all")
})
```

`RouterAt(url)` is a wrapper built like `renderAt` that renders `children` on the matching
route. A hook test is for the mapping rules (defaults, off values, the page reset); whether the
screen follows the URL is the component tests above.
