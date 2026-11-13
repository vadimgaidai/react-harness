# Lifecycle: identity, staleness, cleanup, state models

> What separates a deliberate draft from a synced copy, a stale async result from a fresh one,
> a cleanup from a guard, a pure render from one that writes, and a union of states from loose
> flags? Replace the placeholders (`[Entity]`) with real names.

## Component identity: the accidental sync versus the intentional draft

**The bug** — an effect syncing a prop into state because the prop changed. `effects.md`
already shows this: the effect is extra renders and a stale frame for no reason, because the
component should either read the prop directly or let `key` reset it.

**The legitimate twin** — a component that copies a query value into state *on purpose*,
because the user rearranges a draft before saving it back. This is not a finding; the draft is
the component's own state, not a duplicate of the query's. A form is not this case: a form's
draft belongs to `react-hook-form-zod` (`values` with `keepDirtyValues`, `key` on a new entity).

```tsx
interface I[Entity]OrderEditorProps {
  items: Array<I[Entity]>
}

const [Entity]OrderEditor = ({ items }: I[Entity]OrderEditorProps) => {
  const [order, setOrder] = useState(() => items.map((item) => item.id))
  const { mutate, isPending } = use[Entity]ReorderMutation()

  return (
    <>
      <SortableList ids={order} onReorder={setOrder} />
      <Button disabled={isPending} onClick={() => mutate(order)}>
        {t("actions.save")}
      </Button>
    </>
  )
}

<[Entity]OrderEditor key={listId} items={items} />
```

The test: does the component ever write the prop's *current* value back into state
on a dependency change? The bug does, every time, which makes the state a lagging copy. The
draft does not: it is seeded once per `listId` and then diverges from the query on purpose,
until save. `key={listId}` resets the draft when the editor is pointed at a different list; an
effect that called `setOrder(...)` on every refetch would throw away the user's rearrangement,
which is the bug, not the feature.

## Stale async results

A search box whose last keystroke's response can still outrun an earlier one. Without the
`ignore` guard below, the slower response wins however it lands:

```tsx
useEffect(() => {
  let ignore = false
  searchApi.search(query).then((results) => {
    if (!ignore) {
      setResults(results)
    }
  })
  return () => {
    ignore = true
  }
}, [query])
```

The `ignore` flag is the minimum fix for a hand-rolled effect: cleanup runs before the next
effect, so a response arriving after `query` changed again is dropped. The query cache does
the same thing by construction — a `useQuery` keyed on `query` discards a response for a key
that is no longer the active one, so prefer it over hand-rolled fetching entirely
(`tanstack-query` skill).

## Cleanup: with and without release

The first leaks — the listener survives the component:

```tsx
useEffect(() => {
  window.addEventListener("resize", updateWidth)
}, [])
```

The second releases what it acquired:

```tsx
useEffect(() => {
  window.addEventListener("resize", updateWidth)
  return () => window.removeEventListener("resize", updateWidth)
}, [])
```

React runs setup, cleanup and setup again in development, and again whenever a dependency
changes, so the second setup must leave nothing extra behind: one listener, one socket, one
timer.

A `hasRun` ref that skips the body on the second call prevents a duplicate side effect; it
does not release whatever the first call acquired. Both problems can be present in the same
effect — guarding re-entry is not a substitute for a cleanup function.

## Render purity and immutability

Render computes output from props and state and does nothing else. A mutation, a toast, a
navigation, a storage write or a write to a module-level variable while rendering runs again on
every render, twice in StrictMode, and belongs in a handler or an effect.

A call that returns something new each time breaks the same rule: `Date.now()`, `new Date()`,
`Math.random()`, `crypto.randomUUID()` in the body of a component give a different render for
the same props, and the Compiler's `purity` lint reports them. A value fixed for the component's
life goes in a lazy initializer (`useState(() => Date.now())`), an id for markup comes from
`useId`, and a time that should tick is state updated by a timer in an effect.

Props, state and query data are read-only. The first sorts the cached array in place, so every
other reader of that query now sees it reordered:

```tsx
const ranked = data.items.sort(byScore)
```

A sorted or filtered view is a new array:

```tsx
const ranked = data.items.toSorted(byScore)
```

The same holds for `reverse`, `splice`, `push` and property assignment on anything React or the
cache handed you: `toReversed`, `toSpliced`, spread, or `structuredClone` before editing.

## State model: a union instead of independent flags

The interface admits `isLoading: true`, `isError: true` and `data` present — all three at
once; the union admits exactly the three states that can occur:

```ts
interface I[Entity]State {
  isLoading: boolean
  isError: boolean
  data?: I[Entity]
}

type T[Entity]State =
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "success"; data: I[Entity] }
```

The query cache already returns a union (`tanstack-query` skill, §States) — this shape is for
local state that tracks a multi-step process (upload progress, a wizard) the cache doesn't
cover. The test: can two fields disagree about what is currently true? If so, the type should
have refused to let that value exist.
