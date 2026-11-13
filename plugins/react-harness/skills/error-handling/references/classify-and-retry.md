# Classifying a failure and retrying it

Answers: which class a failure belongs to, which message and next step each class gets, and
when an operation may be retried.

> The examples use `ky` (`HTTPError`, `TimeoutError`). Read the project's HTTP client in
> `package.json` once and use its classes from the table under "The same classes in each
> client". Every user-facing string is a `t()` key; `[entity]` is a placeholder.

## Classify before messaging

Four classes: known HTTP status, network/timeout, cancelled, unknown. Unknown is not network,
and an unmapped 4xx is not a server error. One generic toast for every class leaves the user
without a next step.

```ts
const describe = (error: unknown): IErrorDescription => {
  if (!(error instanceof HTTPError)) {
    return { messageKey: "errors.network", retryable: true }
  }

  const { status } = error.response
  const messageKey = MESSAGE_KEY_BY_STATUS[status] ?? "errors.server"

  return { messageKey, retryable: status >= 500 }
}
```

A `TypeError` from a bug, a `ZodError` from a bad contract and an aborted request all become
"network, retry", and an unmapped `422` becomes "server error". Four classes, each its own
text and its own retry answer:

```ts
const MESSAGE_KEY_BY_STATUS: Record<number, string> = {
  403: "[entity].errors.forbidden",
  409: "[entity].errors.conflict",
  429: "errors.rateLimited",
}

const describe = (error: unknown): IErrorDescription => {
  if (error instanceof HTTPError) {
    const { status, headers } = error.response
    const isServer = status >= 500
    const retryAfterMs = status === 429 ? parseRetryAfter(headers.get("Retry-After")) : undefined

    return {
      kind: "http",
      messageKey: MESSAGE_KEY_BY_STATUS[status] ?? (isServer ? "errors.server" : "errors.request"),
      retryable: isServer || status === 429,
      retryAfterMs,
    }
  }

  if (error instanceof TimeoutError || error instanceof TypeError) {
    return { kind: "network", messageKey: "errors.network", retryable: true }
  }

  if (error instanceof DOMException && error.name === "AbortError") {
    return { kind: "cancelled", messageKey: null, retryable: false }
  }

  return { kind: "unknown", messageKey: "errors.unexpected", retryable: false }
}
```

`fetch` rejects a network failure with a `TypeError`; `ky` adds `TimeoutError`. A cancelled
request gets no toast — the user navigated away. Unknown is reported, not retried, and the
original error is kept for the error reporter. The UI reads `retryable` and `retryAfterMs` to
choose between a retry button, a wait, and a dismissable message.

## The same classes in each client

| Class | `ky` | `axios` | `fetch` |
|---|---|---|---|
| HTTP status | `error instanceof HTTPError`, `error.response.status` | `isAxiosError(error) && error.response`, `error.response.status` | does not reject on a status: check `response.ok` and throw the project's own error with the status |
| Network | `TypeError` | `isAxiosError(error) && !error.response` (`code === "ERR_NETWORK"`) | `TypeError` |
| Timeout | `TimeoutError` (`timeout` option, 10 s by default) | `code === "ECONNABORTED"` or `"ETIMEDOUT"` (`timeout` option, none by default) | `DOMException` named `"TimeoutError"` from `AbortSignal.timeout(ms)` |
| Cancelled | `DOMException` named `"AbortError"` | `isCancel(error)` (`code === "ERR_CANCELED"`) | `DOMException` named `"AbortError"` |
| Built-in retry | `GET`, `PUT`, `HEAD`, `DELETE`, `OPTIONS`, `TRACE` on `408`/`413`/`429`/5xx, twice, honouring `Retry-After`; never `POST` | none | none |

`describe()` keeps the same four outputs whatever the client; only the checks inside it change.
With `axios` or `fetch` nothing below the query cache retries, so the shared `QueryClient`'s
`retry` predicate is the only retry layer.

## Retry is failure kind × operation safety

```ts
mutationOptions({ mutationFn: [entity]Api.publish, retry: 2 })
```

A retried `POST` that succeeded the first time is a duplicate. Two inputs decide a retry: the
failure must be transient (network, timeout, `429` after `Retry-After`, 5xx), and repeating
the operation must be safe. Reads are safe; a write is safe only when the server deduplicates
it by an idempotency key, and the same key is sent unchanged on every attempt:

```ts
mutationOptions({
  mutationFn: ({ id, idempotencyKey }: IPublishInput) =>
    [entity]Api.publish(id, { headers: { "Idempotency-Key": idempotencyKey } }),
  // ! server dedupes by Idempotency-Key, so a repeat is safe
  retry: (failureCount, error) => failureCount < 2 && describe(error).retryable,
})
```

The key is generated once per user intent, not per attempt. Read what the HTTP client and the
shared `QueryClient` already retry before adding a layer (the table above). What the shared `QueryClient` retries, and the comment an override needs, is the
`tanstack-query` skill's rule on reading the shared client.
