# What a catch may do

Answers: may this `catch` exist, and what must its body do — translate, recover to an
explicit outcome, or rethrow after work — and does the `try` guard anything at all?

> Replace the placeholders (`[entity]`, `[Entity]`) with real names. Every user-facing string
> is a `t()` key.

## A catch does one of three things

It translates, recovers to an explicit outcome, or rethrows after doing work. "Recover" never
means returning something the caller reads as success. Log-and-continue and an empty catch
are deleted errors; a catch that only rethrows is a `try` to delete.

```ts
try {
  await [entity]Api.publish(id)
} catch (error) {
  console.error(error)
}
```

Logged and forgotten; the caller believes it published.

Translate:

```ts
catch (error) {
  throw new PublishError(id, { cause: error })
}
```

Recover — to an outcome the caller can read, never to a value that looks like success:

```ts
const publish = async (id: string): Promise<TPublishOutcome> => {
  try {
    await [entity]Api.publish(id)
    return { status: "published" }
  } catch (error) {
    if (isConflict(error)) {
      await queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })
      return { status: "conflict" }
    }
    throw error
  }
}
```

`return refetch()` here would hand the caller fresh data and a resolved promise — a success
toast on a publish that never happened. The caller branches on `status` and shows the conflict
copy with the refreshed entity.

Rethrow after work:

```ts
catch (error) {
  restoreDraft(snapshot)
  throw error
}
```

The catch did something the caller cannot: undo local state. A catch whose body is only
`throw error` did nothing, and the `try` is deleted.

## Catch what can throw here

Open the callee before writing or keeping a `try`. A `try` with a placeholder result like
`"—"` needs a named failure it is handling.

```ts
try {
  const total = items.reduce((sum, item) => sum + item.price, 0)
  return formatAmount(total)
} catch {
  return "—"
}
```

Open `formatAmount`. If it is `Intl.NumberFormat` with a currency code from the data, an
unknown code throws a `RangeError` — then the catch handles a named failure and says so:

```ts
catch (error) {
  if (error instanceof RangeError) {
    return t("errors.badCurrency")
  }
  throw error
}
```

If it only concatenates strings, nothing in the block throws, the `try` documents a fear, and
`"—"` would hide a wrong total behind a dash. Either way the decision comes from the callee,
not from the shape of the block.
