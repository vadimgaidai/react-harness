# Reviewing: react-testing

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- an assertion on an internal state variable or a call count instead of the rendered result
- the component or hook under test itself mocked, rather than only the network boundary
- a fixed sleep/timer instead of `findBy*`/`waitFor` for async UI
- only the happy path tested — no pending, failure or retry-after-failure case
- a form test that checks `onSubmit` fired but not the error text or the sent payload
- `useQuery`/`useMutation` mocked instead of run through a real `QueryClient`
- a subscription or timer never asserted gone after unmount
- a test file whose assertions are actually a `PASS`-printing stub, cited as if it were a run
- `getByTestId` where the element has a role or a label, or a query for an exact full sentence instead of a loose regex on its meaning
- a test that renders translation keys, mocks `t`, or ignores a missing-key error instead of the real main-language translations
- a component that reads the URL tested without the router, with its filters passed as props or a mocked `useSearchParams`/`useSearch`
- a component that reads `useSuspenseQuery` rendered without a `Suspense` boundary, or a pending state looked up by a "Loading" text
- MSW without `onUnhandledRequest: "error"`, so an undescribed request passes silently
