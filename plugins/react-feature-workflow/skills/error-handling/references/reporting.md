# Reporting an error once

Answers: where does an error go to the tracker (Sentry or the project's own), and where does a background error become a toast, so neither happens twice or not at all?

> `errorReporter.capture(error, context)` stands for the project's tracker call. `i18n.t` is the
> i18n instance's `t`, since these handlers run outside a component.

## One place per source

Three sources cover every error the app does not handle itself:

- a render error: `createRoot`'s options (React 19);
- a request error: the shared `QueryCache` `onError`;
- an action error: the shared `MutationCache` `onError`.

A `catch` that calls `console.error` or the tracker beside them reports the same error twice, or
reports one the caller then recovers from. It handles the error (`references/catch.md`) and
leaves reporting to these three.

```tsx
const reportRenderError = (error: unknown, errorInfo: ErrorInfo) => {
  errorReporter.capture(error, { componentStack: errorInfo.componentStack })
}

createRoot(container, {
  onUncaughtError: reportRenderError,
  onCaughtError: reportRenderError,
  onRecoverableError: reportRenderError,
}).render(<App />)
```

`onUncaughtError` fires for an error no boundary caught, `onCaughtError` for one an error
boundary caught and rendered a fallback for, `onRecoverableError` for one React recovered from
on its own (a hydration mismatch). An error boundary therefore does not report in its own
`componentDidCatch` or `onError` as well.

## Request and action errors

```ts
declare module "@tanstack/react-query" {
  interface Register {
    queryMeta: { errorMessage?: string }
  }
}

export const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (error, query) => {
      if (describe(error).kind === "unknown") {
        errorReporter.capture(error, { queryKey: query.queryKey })
      }

      if (query.state.data !== undefined && query.meta?.errorMessage) {
        toast.error(i18n.t(query.meta.errorMessage))
      }
    },
  }),
  mutationCache: new MutationCache({
    onError: (error, _variables, _context, mutation) => {
      if (describe(error).kind === "unknown") {
        errorReporter.capture(error, { mutationKey: mutation.options.mutationKey })
      }
    },
  }),
})
```

Only the unknown class goes to the tracker: a `403`, a conflict or a dropped connection is an
expected outcome with its own message, and reporting it buries the real bugs.

The toast fires only when the query already has data, so it is a background refetch that
failed while the user still sees the old screen. A failed first load has no data and renders
the screen's error state instead (`owners.md`, a request error is a query state); a toast on top
of that error screen says the same thing twice. A query whose screen renders the inline refetch
alert (`owners.md`) sets no `meta.errorMessage`; a query whose screen shows none opts in with its message:

```ts
queryOptions({
  queryKey: [entity]Keys.list(filters),
  queryFn: () => [entity]Api.getList(filters),
  meta: { errorMessage: "[entity].errors.refreshFailed" },
})
```

An action's toast is the mutation hook's own `onError` (`owners.md`); the `MutationCache`
handler reports and does not toast, so an action never notifies twice.
