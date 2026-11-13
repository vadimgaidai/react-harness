# Actions, Transitions and `use`

> Which React 19 hook owns a pending flag, an optimistic value or a promise in this stack?
> Replace the placeholders (`[Entity]`,
> `I[Entity]`) with real names.

## `useTransition` — async actions without a manual pending flag

```tsx
const [isPending, startTransition] = useTransition()

const export[Entity]s = () => {
  startTransition(async () => {
    await [entity]Api.exportCsv(filters)
  })
}

return <Button onClick={export[Entity]s} disabled={isPending}>{t("[entity].export")}</Button>
```

`isPending` stays `true` for the whole async body, so a hand-rolled `const [isLoading, setIsLoading] = useState(false)` around non-form async work is redundant. A state update after an `await` is no longer part of the transition; wrap it in `startTransition` again:

```tsx
startTransition(async () => {
  const file = await [entity]Api.exportCsv(filters)
  startTransition(() => {
    setLastExport(file)
  })
})
```

Errors are not caught for you: `try`/`catch` inside the transition, or let an error boundary take it.

Around a navigation, a transition keeps the outgoing screen on-screen instead of flashing a Suspense fallback:

```tsx
startTransition(() => navigate(paths.[entity].details(id)))
```

**In a project using React Hook Form,** `formState.isSubmitting` and the mutation's `isPending` already cover form submits. Reach for `useTransition` for non-form async work — a navigation, a tab switch that mounts a lazy panel, a filter that swaps an expensive view.

## `useOptimistic` — local optimistic value

```tsx
const [optimisticItems, addOptimisticItem] = useOptimistic(
  items,
  (current: I[Entity][], pending: I[Entity]) => [...current, pending]
)

const add[Entity] = (draft: I[Entity]) => {
  startTransition(async () => {
    addOptimisticItem(draft)
    await create(draft)
  })
}
```

- `addOptimistic` may only be called inside a transition or an action. Outside one, React warns and the value snaps back immediately.
- The optimistic value reverts on its own when the action settles — there is no rollback to write. That is the whole advantage over doing it by hand.
- The base value must be the real one. Feeding it state you already mutated optimistically gives you a double-applied update.

**Choose one layer.** If the value comes from the query cache, do the optimistic update in the mutation's `onMutate` (see the `tanstack-query` skill) and leave `useOptimistic` alone. Using both on the same value produces two competing rollbacks.

## Form actions

`useActionState`, `<form action>` and `useFormStatus` stay out: a form goes through React Hook
Form + Zod, and the reason is in the `react-hook-form-zod` skill (`references/form.md`).

## `use`

```tsx
const theme = use(ThemeContext)
const message = use(messagePromise)
```

`use(Context)` may be called conditionally, unlike `useContext`. `use(promise)` suspends until the promise resolves, and the promise must be created outside render — it has to be stable across renders: created by a cache, a suspense-aware library, or passed down as a prop. `use(fetch(url))` in a component body creates a new promise every render and suspends forever.

In this stack the promise form is rarely the right tool — `useSuspenseQuery` gives you the same suspension with caching, deduplication and invalidation. Reach for `use(Context)` freely; reach for `use(promise)` only when there is a real promise you already own.
