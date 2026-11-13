---
name: react
description: React 19 with the React Compiler — where state lives, what an effect is for, when useMemo or useCallback stays, refs, context, keys, lazy + Suspense, error boundaries, useTransition, useDeferredValue, useOptimistic, use, useEffectEvent, Activity and ViewTransition. Use when writing or reviewing a component or hook in a .tsx file, when the task names useState, useEffect, useMemo, useCallback, useRef, useContext, a re-render, memo, key, forwardRef, lazy, Suspense, an error boundary, a tab that keeps its state or an animation, or when adding a route, modal or heavy widget.
---

# React 19

For React 19 with the Compiler; check `package.json` once per session, since React 18 still needs `forwardRef` and `Context.Provider`, `useEffectEvent` and `<Activity>` need 19.2, and `<ViewTransition>` and Fragment refs need 19.3 (table in [references/state-and-rendering.md](references/state-and-rendering.md)).

- State sits in the lowest subtree that reads it; lift only to the closest common ancestor.
- Server data lives in the query cache, URL state in the query string, anything computable in render.
- State that changes together is one state; flags that can both be true are a union (`typescript` skill).
- A value nothing renders (an id, a timer handle) is a ref; `ref.current` is never touched during render.
- Render is pure: no mutation, toast, navigation, storage or global write, and no `Date.now()`, `Math.random()` or `new Date()`, since render runs again and must give the same output; props, state and query data are copied, never changed in place.
- An effect only syncs with something outside React; a derived value is computed in render, an event's side effect runs in its handler, fetching belongs to the query cache.
- A function an effect calls that must see the latest props without re-running the effect is a `useEffectEvent` (19.2), never a ref holding the latest value or a dependency left out; it is not a way to silence the linter.
- `key` resets a draft copied from a prop on purpose; it does not excuse a prop synced by mistake.
- An effect that subscribes, opens or schedules returns a cleanup; a `hasRun` flag guards firing, not releasing.
- An async result whose input has since changed is stale: compare it with the current input, or let the query key do it.
- `useMemo`/`useCallback` stays only for expensive work on stable inputs or a reference something depends on.
- A scan over a second collection per rendered item becomes a lookup built once (`code-shape` skill).
- Keys are identities, never an index on a list that reorders, filters or grows, since an index key hands one row's state to another; no component defined inside another's render, since it remounts on every render of the parent.
- A condition in JSX is a boolean (`items.length > 0 && …`), since `0 && …` renders `0`.
- A fast input that drives an expensive render hands the slow part a `useDeferredValue`, so typing stays responsive.
- A tab or panel that keeps its state while hidden goes in `<Activity mode>` (19.2) instead of a condition that unmounts it; a hidden activity also unmounts its effects.
- Static JSX and objects are hoisted, so they keep one reference across renders; `useState(() => expensive())` for real setup; functional `setState` when the next value reads the previous.
- Context holds ambient, rarely changing values; split churning from stable, and try `children` composition first.
- React 19: `ref` is a plain prop, `<Context value>` is the provider, `use(Context)` may be conditional, no blanket `memo`.
- Lazy-load routes, modal and drawer content, heavy widgets, anything behind a tab, step or permission; never above the fold.
- One `<Suspense>` per route and per region that loads on its own, each with an error boundary beside it; a query-backed region uses the one `QueryBoundary` ([references/code-splitting.md](references/code-splitting.md)).
- `useTransition` owns the pending flag for non-form async work; `useOptimistic` only for a value the query cache does not own.
- A form goes through `react-hook-form-zod`, never `useActionState`, `<form action>` or `useFormStatus`, not even for one field; the reason is in that skill.
- `use(promise)` takes a promise created outside render, since one created in render is new every time and suspends forever; it is not a fetching hook.

## Example

A prop copied into state and synced by an effect renders twice per change and shows a stale frame between them:

```tsx
const [label, setLabel] = useState(formatLabel(value))
useEffect(() => {
  setLabel(formatLabel(value))
}, [value])
```

The value is computed in render:

```tsx
const label = formatLabel(value)
```

A draft the user edits before saving is the exception: it is seeded once and reset with `key` ([references/lifecycle.md](references/lifecycle.md)). A previous value that is rendered is state adjusted during render ([references/effects.md](references/effects.md)).

## References

- [references/effects.md](references/effects.md): before writing or keeping a `useEffect`, and for `useEffectEvent`.
- [references/lifecycle.md](references/lifecycle.md): a draft seeded from a prop, a stale async result, a cleanup, render purity, a union of states.
- [references/state-and-rendering.md](references/state-and-rendering.md): placing state, keeping or dropping a memo, keys, refs, context, a numeric JSX condition, `useDeferredValue`, `<Activity>`, APIs the Compiler skips, the version table, `<ViewTransition>`, a Fragment ref.
- [references/code-splitting.md](references/code-splitting.md): a route, modal or heavy widget; Suspense and error boundaries; a retry.
- [references/actions.md](references/actions.md): `useTransition`, `useOptimistic` and `use`.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
