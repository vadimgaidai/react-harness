# Test setup: providers, translations, the network

Answers: what does a component test render around the component, how do translations and the network get into it, and what changes under Vitest Browser Mode?

> Canonical code shape. Shown for Vitest + React Testing Library + MSW + i18next; a Jest
> project swaps `vi` for `jest`. Placement of the helper and the setup file: the structure
> skill loaded in this project.

## `renderWithProviders`

```tsx
const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })

export const renderWithProviders = (ui: ReactNode) => {
  const queryClient = createTestQueryClient()

  return render(
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <Suspense fallback={<Spinner />}>{ui}</Suspense>
      </I18nextProvider>
    </QueryClientProvider>
  )
}
```

- A new `QueryClient` per test, so one test's cache never answers another's request.
- `retry: false`, so a failure test does not wait out the backoff; the production client's
  retry policy is `tanstack-query`'s, not the test's.
- `<Suspense>` lets a component that reads `useSuspenseQuery` render; its fallback is the
  pending state a test can find by role (`Spinner` is `role="status"`).
- A component that reads the URL renders through [url-state.md](url-state.md) instead, which
  adds the router around the same providers.

## Translations: the real ones

```tsx
export const testI18n = i18next.createInstance()

await testI18n.use(initReactI18next).init({
  lng: "en",
  resources: { en: { translation: enTranslation } },
  interpolation: { escapeValue: false },
  saveMissing: true,
  missingKeyHandler: (_languages, _namespace, key) => {
    throw new Error(`Missing translation: ${key}`)
  },
})
```

The test instance loads the project's own main-language file, so a test finds the text the
user reads: `getByRole("button", { name: /save/i })`. A key with no entry throws instead of
rendering the key, so a missing translation fails the test that renders it. Text is matched by a
loose regex on its meaning, not the whole sentence, so rewording `"Save changes"` to
`"Save"` leaves the test green. Use the project's own language and file layout; a project on
another i18n library does the same through its own provider.

## The network: one MSW server

```tsx
export const server = setupServer()

beforeAll(() => server.listen({ onUnhandledRequest: "error" }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

In the setup file. `onUnhandledRequest: "error"` fails a test whose component calls an endpoint
the test never described, instead of letting it hit the real network or hang. Each test adds
its own handlers with `server.use(...)`; `resetHandlers` drops them after it.

## Vitest Browser Mode

Vitest 4 made Browser Mode stable: tests run in a real browser through a provider package
(`@vitest/browser-playwright` or another `@vitest/browser-*`). When `package.json` has one:

- `render` comes from `vitest-browser-react` instead of `@testing-library/react`;
- elements are found through locators (`page.getByRole(...)`), with the same priority as above;
- an assertion on async UI is `await expect.element(locator).toBeVisible()`, which retries until
  it holds, in place of `findBy*`;
- user input goes through the browser's own events, so `user-event` is not needed.

Import paths moved between Vitest versions; take them from the installed version's docs. The
rules of this skill do not change: real providers, network mocked at the boundary, assertions
on what the user sees.
