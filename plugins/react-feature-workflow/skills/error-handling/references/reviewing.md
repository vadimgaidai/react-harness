# Reviewing: error-handling

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

Name the consequence, not the construct. A `try/catch`, a fallback, an optional chain or a
local `onError` is not a finding by itself — say which of these it causes:

- **lost error** — log-and-continue, empty catch, `queryFn` that swallows, `?? []` where the
  error branch should be
- **false success** — a catch that returns a value the caller treats as done, a follow-up that
  runs before the write landed
- **duplicate notification** — toast in the handler and in `onError`, local `onError` beside
  a `MutationCache`/`QueryCache` handler that already toasts
- **wrong UI state** — data read before the pending branch, a refetch error blanking data the
  cache still holds, a success toast on a conflict
- **unsafe retry** — a retried non-idempotent write, a retry that ignores `Retry-After`, an
  unknown error classified as network and retried
- **lost callback** — `...options, onError` that drops the rollback the options carried
- **double report** — a `console.error` or a tracker call in a `catch`, a boundary or a hook
  beside the root options and the cache handlers that already report
- **wrong client** — `HTTPError`/`TimeoutError` checks in a project whose client is `axios` or
  `fetch`, or a `fetch` response used without checking `response.ok`
