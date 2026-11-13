---
name: error-handling
description: Who owns an error in this stack — the cache owns request errors, one owner per action notification (the mutation's onError), the resolver owns client form rules and setError what only the server knows, a catch translates, recovers to an explicit outcome or rethrows. Use when writing or reviewing a try/catch, throw, toast, onError, setError, an error state or error boundary, a retry, error reporting to Sentry or a tracker, an HTTP client's errors (ky, axios, fetch), or a fallback like `?? []` in a component, hook or API module.
---

# Error handling

- The cache owns request errors: a suspense read's failed first load goes to its region's `QueryBoundary`, a `useQuery` read renders `isError` inline; a `queryFn` `try/catch` that copies the error into state or swallows it goes.
- `?? []` and `?.` sit on values the contract makes optional, never in place of the error branch or over a required field.
- One owner per user notification: an action's toast is the mutation hook's `onError`; a caller's `catch` is control flow, never a second toast.
- An `onError` added over spread options calls the one it replaces, or the rollback it carried is gone.
- The resolver owns client rules; `setError` owns what only the server knows (an API field, or `root.*`); moving a check into the schema leaves the payload unchanged.
- A `catch` translates, recovers to an explicit outcome, or rethrows after doing work; it never returns what the caller reads as success.
- Log-and-continue and an empty catch delete the error; a catch that only rethrows means the `try` goes.
- An error is reported to the tracker from one place, `createRoot`'s `onCaughtError`/`onUncaughtError`/`onRecoverableError` and the `QueryCache`/`MutationCache` `onError`, never by a `console.error` in each `catch`.
- A background refetch error notifies once: the screen's inline alert over the kept data, or, on a screen that shows no alert, a toast from the shared `QueryCache` `onError` through the query's `meta.errorMessage`, never both; a failed first load is the screen's error state, not a toast (`tanstack-query`).
- Catch only what can throw here: open the callee and name the failure the catch handles.
- Read the HTTP client in `package.json` once (`ky`, `axios`, `fetch`): its error classes, its timeout and its built-in retries differ, and the classification uses that client's.
- Classify before messaging — known HTTP status, network/timeout, cancelled, unknown — each with its own `t()` text.
- Retry only a transient failure (network, timeout, `429` after `Retry-After`, 5xx) on a read or a write deduplicated by an idempotency key, after reading what the HTTP client and shared `QueryClient` already retry.

Which query state to read, when a boundary takes the error and where a mutation's callbacks go
are the `tanstack-query` skill's rules.

## Example

Two owners for one failure: `use[Entity]UpdateMutation` already toasts in its `onError`, and the caller's `catch` toasts again.

```tsx
const { mutateAsync } = use[Entity]UpdateMutation()

const onSubmit = async (values: T[Entity]Form) => {
  try {
    await mutateAsync(values)
    onClose()
  } catch {
    toast.error(t("[entity].errors.save"))
  }
}
```

The follow-up goes in the per-call `onSuccess`, and failure reaches the hook's `onError` alone:

```tsx
const { mutate } = use[Entity]UpdateMutation()

const onSubmit = (values: T[Entity]Form) => mutate(values, { onSuccess: onClose })
```

## References

- [references/owners.md](references/owners.md): when deciding who owns an error: query states over a `queryFn` catch, a fallback against an error branch, the action's toast, a chained `mutateAsync`, `onError` over spread options, schema rule against `setError`.
- [references/catch.md](references/catch.md): when writing or keeping a `try/catch`: translate, recover, rethrow after work, and checking the callee can throw.
- [references/classify-and-retry.md](references/classify-and-retry.md): when mapping an error to a message or adding a `retry`: the four classes, `describe()`, idempotency keys, and the same classes in `ky`, `axios` and `fetch`.
- [references/reporting.md](references/reporting.md): when wiring error reporting, a root, the shared `QueryClient`'s cache handlers, or a background-error toast.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
