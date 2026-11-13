# A component test with a real `QueryClient`

Answers: how to drive a component that reads a query through success, pending, failure and retry over the network, and how to test that a subscription is released on unmount.

> Canonical code shape. Replace the placeholders (`[Entity]`) with real names. Shown for
> Vitest + React Testing Library + MSW; a Jest project swaps `vi` for `jest`. Text queries read
> the real translations ([setup.md](setup.md)).

```tsx
test("shows the item once the request resolves", async () => {
  server.use(
    http.get("/api/[entity]s/:id", () => HttpResponse.json({ id: "1", name: "Widget" }))
  )

  renderWithProviders(<[Entity]Badge id="1" />)

  expect(screen.getByRole("status")).toBeInTheDocument()
  expect(await screen.findByText("Widget")).toBeInTheDocument()
})

test("shows a retry affordance on failure", async () => {
  server.use(http.get("/api/[entity]s/:id", () => HttpResponse.error()))

  renderWithProviders(<[Entity]Badge id="1" />)

  expect(await screen.findByRole("alert")).toHaveTextContent(/couldn't load/i)
})

test("loads the item after a retry", async () => {
  const user = userEvent.setup()
  server.use(
    http.get("/api/[entity]s/:id", () => HttpResponse.error(), { once: true }),
    http.get("/api/[entity]s/:id", () => HttpResponse.json({ id: "1", name: "Widget" }))
  )

  renderWithProviders(<[Entity]Badge id="1" />)
  await user.click(await screen.findByRole("button", { name: /try again/i }))

  expect(await screen.findByText("Widget")).toBeInTheDocument()
})
```

The pending render is found by its role: a `Spinner` is `role="status"`, a region filled with
`Skeleton`s carries `aria-busy="true"` (`getByRole("region", { busy: true })`). A test that
looks for "Loading…" text tests a string the design does not have. `renderWithProviders` is in
[setup.md](setup.md).

`retry: false` on the test client is what keeps the failure test fast and deterministic — the
production client's own retry policy is `tanstack-query`'s concern, not this test's. Mocking
the HTTP layer (MSW) instead of `useQuery` itself means the real query — its key, its `select`,
its error classification — is what runs; a `vi.mock("@tanstack/react-query")` that returns
`{ data: mockItem, isPending: false }` directly proves nothing about whether the component
asked for the right key.

## Unmount and a subscription

```tsx
test("unsubscribes from the store on unmount", () => {
  const unsubscribe = vi.fn()
  vi.spyOn(networkStatusStore, "subscribe").mockReturnValue(unsubscribe)

  const { unmount } = render(<OnlineIndicator />)
  unmount()

  expect(unsubscribe).toHaveBeenCalledOnce()
})
```

This is the test `react`'s cleanup rule is for: a component that subscribes without returning
a cleanup passes every other test in the suite and fails only this one.
