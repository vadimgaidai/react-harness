# Who owns this error

Answers: which code owns a given error — the cache, the mutation hook, the caller, the
resolver or `setError` — and what each owner's code looks like next to the hunk it replaces.

> Replace the placeholders (`[entity]`, `[Entity]`, `I[Entity]`) with real names. Every
> user-facing string is a `t()` key; `t` comes from `useTranslation()` in the component.
> Which query state to read, when a boundary takes the error, and where a mutation's
> callbacks go are the `tanstack-query` skill's rules; this file only says who owns the error.

## A request error is a query state

The cache owns request errors. A `try/catch` inside a `queryFn` that mirrors the error into
state is a second copy of the cache; one that swallows is a deleted error.

```tsx
const [error, setError] = useState<Error | null>(null)
const { data } = useQuery({
  ...[entity]Queries.list(filters),
  queryFn: async (ctx) => {
    try {
      return await [entity]Api.getList(filters, ctx)
    } catch (e) {
      setError(e as Error)
      throw e
    }
  },
})

return <[Entity]List items={data.items} />
```

Two bugs: the cache already holds `error`, and `data` is `undefined` while pending, so
`data.items` throws on first render. Let the cache's owner render it instead — which hook, and
when a boundary takes the error, is the `tanstack-query` skill. A suspense read hands the failed
first load to its region's `QueryBoundary` and keeps only the refetch error:

```tsx
const { data, isRefetchError } = useSuspenseQuery([entity]Queries.list(filters))

if (data.items.length === 0) {
  return <EmptyState title={t("[entity].empty")} />
}

return (
  <>
    {isRefetchError && <InlineAlert message={t("errors.refreshFailed")} />}
    <[Entity]List items={data.items} />
  </>
)
```

A read that stays on `useQuery` owns the same failures inline:

```tsx
const { data, isPending, isLoadingError, isRefetchError, error, refetch } = useQuery(
  [entity]Queries.list(filters),
)

if (isPending) {
  return <[Entity]ListSkeleton />
}

if (isLoadingError) {
  return <ErrorState error={error} onRetry={refetch} />
}

if (data.items.length === 0) {
  return <EmptyState title={t("[entity].empty")} />
}

return (
  <>
    {isRefetchError && <InlineAlert message={t("errors.refreshFailed")} onRetry={refetch} />}
    <[Entity]List items={data.items} />
  </>
)
```

What this skill cares about: the failed first load has one owner (the boundary, or the
`isLoadingError` branch), the empty response has its own copy, and a refetch error does not
blank data the user already has. The boundary's reset shape is in the `react` skill,
references/code-splitting.md, "`QueryBoundary`".

## A fallback is not an error branch

`?? []` and `?.` are fine on a value the contract makes optional. They are a finding when they
stand in for the error branch or paper over a required field. `data?.items ?? []` in place of
the branches above renders the empty state for a failed first load — that is the fallback to
flag, not the operator.

## One owner for the action's toast

For an action, the notification belongs to the mutation hook's `onError`.

`use[Entity]UpdateMutation` toasts in its own `onError`:

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

Two toasts for one failure. The hook owns the notification; the call site's follow-up goes
where the `tanstack-query` skill puts a mutation's per-call callbacks:

```tsx
const { mutate } = use[Entity]UpdateMutation()

const onSubmit = (values: T[Entity]Form) => mutate(values, { onSuccess: onClose })
```

Nothing to catch: failure reaches the hook's `onError`, and the dialog stays open because
`onSuccess` never ran.

A `catch` around an awaited mutation is the caller's control flow — stop the chain, keep the
dialog open — never a second toast. Where a chain genuinely awaits a previous result:

```tsx
const onSubmit = async (values: T[Entity]Form) => {
  try {
    const { fileId } = await upload.mutateAsync(values.file)
    await save.mutateAsync({ ...values, fileId })
    onClose()
  } catch {
    // ! each hook's onError already notified; stop the chain, stay open
  }
}
```

## An `onError` over spread options

Overriding a callback on spread options must call the one it replaces, or the rollback it
carried is gone:

```tsx
const options = [entity]Mutations.toggle()

useMutation({
  ...options,
  onError: async (...args) => {
    await options.onError?.(...args)
    toast.error(t(describe(args[0]).messageKey))
  },
})
```

The original runs first and is awaited (`tanstack-query`, extending shared mutation options). Without that line the spread `onError` — and the optimistic rollback it performs — is
replaced, not extended. If a `MutationCache` `onError` on the shared client already toasts,
there is no local toast at all.

## A form error is a schema rule

The resolver owns client rules; `setError` owns what only the server knows.

```tsx
const onSubmit = (values: T[Entity]Form) => {
  if (values.title.trim().length === 0) {
    setError("title", { message: "[entity].form.titleRequired" })
    return
  }
  mutate(values)
}
```

```ts
title: z.string().refine((value) => value.trim().length > 0, "[entity].form.titleRequired")
```

The schema carries the key, the field renders `t(error.message)`, and the payload is
unchanged: the original check only inspected the value. Moving a check into the schema must
not change the payload; a validation that only checked becomes a transform only on purpose.
`z.string().trim().min(1, …)` would also strip whitespace from what is sent — a
normalization, which the `react-hook-form-zod` skill puts in `onSubmit` when building the
payload, and which is a separate decision from moving the rule.

`setError` is for what only the server knows — a field from the API response, or `root.*` for
the whole form — set where the form handles the failure: the mutation's per-call `onError`, or
the `catch` around `mutateAsync` in a submit handler (`react-hook-form-zod`, references/lifecycle.md):

```tsx
onError: (error) => {
  const field = fieldFromApiError(error)

  if (field) {
    setError(field.name, { type: "server", message: field.messageKey })
    return
  }

  setError("root.serverError", { message: describe(error).messageKey })
},
```

Render the root one with `t(errors.root?.serverError?.message)`. Root errors are cleared on
the next submit; field errors set this way persist until the field re-validates.
