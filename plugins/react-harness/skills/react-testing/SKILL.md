---
name: react-testing
description: What a React test must prove and how to review one. Use when writing or reviewing a `*.test.tsx`, `*.test.ts` or `*.spec.tsx` file, or any test that uses Vitest, Jest, React Testing Library (`render`, `screen`, `getBy*`, `findBy*`, `waitFor`, `userEvent`), MSW (`server.use`, `http.get`, `HttpResponse`), `vi.mock`/`jest.mock`, `QueryClientProvider` in a test, a router or i18n in a test, Vitest Browser Mode, or tests a component, hook, form submit, query loading/error state, or unmount cleanup.
---

# React testing

- Assert what the user sees or what the network received, never a state variable or a call count on the component's own internals.
- Find elements the way a user does: `getByRole` with its accessible name first, then `getByLabelText`, then `getByText`; `getByTestId` only for an element with no role and no label, so the test also proves the accessible names the UI rules require.
- Render with the real translations of the project's main language, so a test reads what the user reads and a missing key fails it; match text with a loose regex on its meaning (`/save/i`), so a reworded string does not break the test.
- Mock only the network boundary (an MSW handler, the HTTP client), never the component or hook under test, or the test only proves the mock was called.
- Run a query-backed component through a real `QueryClient` with `retry: false` and a `<Suspense>` around it, never a mocked `useQuery`/`useMutation` return value, which skips the states `tanstack-query` really produces.
- A component that reads the URL renders inside the project's router with an in-memory history, starting from a real URL, so the test proves filters restore from a link and survive Back (`routing`).
- Await async UI with `findBy*` or `waitFor`, never a fixed sleep, which is slower and still racy.
- Give pending, failure and the retry after a failure each its own test beside the success case; pending is found by its role (`status`, `aria-busy`), not by a "Loading" text the design does not have.
- In a form test, type, submit, and assert both the rendered error text and the payload the network received, not only that `onSubmit` fired.
- Where a component holds a subscription, timer or listener, unmount it and assert the resource is gone, not only that unmount did not throw.
- Cite as a passing check only a real run of the project's runner over real assertions; a script that prints `PASS` is a fixture.

Check `package.json` once per session for the runner (Vitest, Jest), Vitest Browser Mode (`vitest-browser-react` and a `@vitest/browser-*` provider), and the router; the APIs named here are Testing Library's. `verify` runs existing tests and writes none; `implement` or the user writes them where the project has a runner.

## Example

A mocked `useQuery` against a real `QueryClient` with a mocked request:

```tsx
vi.mock("@tanstack/react-query", () => ({
  useQuery: () => ({ data: { id: "1", name: "Widget" }, isPending: false }),
}))

test("shows the item", () => {
  render(<ItemBadge id="1" />)
  expect(screen.getByText("Widget")).toBeInTheDocument()
})
```

```tsx
test("shows the item once the request resolves", async () => {
  server.use(http.get("/api/items/:id", () => HttpResponse.json({ id: "1", name: "Widget" })))

  renderWithProviders(<ItemBadge id="1" />)

  expect(await screen.findByText("Widget")).toBeInTheDocument()
})
```

The first passes even when the component asks for the wrong key; the second runs the real key, `select` and error handling.

## References

- [references/setup.md](references/setup.md): before the first test in a project: `renderWithProviders` (query client, `Suspense`, translations), the MSW server, Vitest Browser Mode.
- [references/component-and-query.md](references/component-and-query.md): a test for a component that reads a query: success, pending, failure, retry, and a subscription released on unmount.
- [references/url-state.md](references/url-state.md): a test for a component or hook that reads the URL, in React Router or TanStack Router.
- [references/form-and-unmount.md](references/form-and-unmount.md): a form test: the submitted payload, a server field error, the pending submit button.
- [references/what-a-test-proves.md](references/what-a-test-proves.md): when a rule above seems not to fit the case, or a review needs the reason behind a finding.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
