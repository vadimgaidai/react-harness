# State placement, memoization and render shape

> Where does a piece of state go, does a memo earn its place, what renders a stray `0`, when do
> `useDeferredValue` and `<Activity>` apply, which API needs which React version, and how do
> `<ViewTransition>` and a Fragment ref work? Replace the placeholders (`[Entity]`, `I[Entity]`) with real names.

Most re-render problems are placement problems; memoization fixes none of them.

## Push state down

```tsx
const [isFilterOpen, setIsFilterOpen] = useState(false)
return (
  <>
    <[Entity]Table rows={rows} />
    <FilterPopover open={isFilterOpen} onOpenChange={setIsFilterOpen} />
  </>
)
```

Every toggle re-renders the table. The flag is read by one subtree:

```tsx
const FilterPopover = () => {
  const [isOpen, setIsOpen] = useState(false)
  …
}
```

Lift only when a second sibling reads it, and only to their closest common parent.

## Not state: derived, server, URL

```tsx
const { data: items = [] } = useQuery([entity]Queries.list(filters))
const activeCount = items.filter((item) => item.status === "active").length
const [searchParams] = useSearchParams()
const page = Number(searchParams.get("page") ?? 1)
```

A computed value is computed; a response lives in the cache; a filter, tab or page the user
expects to survive refresh and back lives in the URL.

## Group what changes together

```tsx
const [position, setPosition] = useState({ x: 0, y: 0 })
```

Two `useState`s updated in the same handler are one piece of state. Three or more fields with
transitions between them are a reducer.

## A ref is a value that never renders

```tsx
const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined)

const schedule = () => {
  clearTimeout(timeoutRef.current)
  timeoutRef.current = setTimeout(save, 500)
}
```

The same value in `useState` re-renders on every schedule for nothing. Read and write
`ref.current` only in handlers, effects and cleanup — never during render. A previous value
that is rendered is state, not a ref ([effects.md](effects.md), keeping the previous value).

`ref` is a plain prop in React 19, and a ref callback may return a cleanup:

```tsx
const Input = ({ ref, ...props }: ComponentProps<"input">) => <input ref={ref} {...props} />
```

## Memoize both-or-neither

The Compiler removes the reflex, not the responsibility. A `useMemo` or `useCallback` buys an
expensive computation or a reference something depends on for stability; one that buys
neither is removed.

```tsx
const activeItems = useMemo(() => items.filter((item) => item.isActive), [items])
const openFilters = useCallback(() => setIsOpen(true), [])
```

A cheap filter and a handler nothing compares by reference: both go.

```tsx
const activeItems = items.filter((item) => item.isActive)
const openFilters = () => setIsOpen(true)
```

A memo that stays:

```tsx
const sorted = useMemo(() => sortByScore(items), [items])
```

Expensive work on stable input. The same `useMemo` with `[filters]` where `filters` is an
object literal built in the parent's render compares every time and never hits — stabilize
the input or drop the memo. An O(n²) body inside `useMemo` is still O(n²): fix it first.

## A lookup instead of a scan

```tsx
const authorById = new Map(authors.map((author) => [author.id, author]))
return comments.map((comment) => (
  <Comment key={comment.id} comment={comment} author={authorById.get(comment.authorId)} />
))
```

`authors.find(…)` inside the `map` is n×m per render. A loop by itself is not the problem;
the repeated scan is. The replacement keeps what the search did: the original order, which
entry wins on a duplicate id, and what renders when the id is missing.

## Keys and hoisting

```tsx
const DEFAULT_FILTERS: I[Entity]Filters = { status: "all", page: 1 }

export const [Entity]List = ({ items }: I[Entity]ListProps) => {
  const [filters, setFilters] = useState(DEFAULT_FILTERS)

  if (items.length === 0) {
    return <EmptyState title={t("[entity].empty")} />
  }

  return items.map((item) => <[Entity]Row key={item.id} item={item} />)
}
```

Static objects sit above the component, so `useState` and any memo see the same reference
every render; keys are identities, never indexes on a list that can reorder, filter or grow.
A component declared inside another's body remounts its whole subtree on every render of the parent: its type changes identity each time, the same loss
of state as a `key` that changes for the wrong reason.

## A number as a JSX condition

```tsx
{items.length && <[Entity]List items={items} />}
```

With an empty list this renders `0`. The condition is a boolean:

```tsx
{items.length > 0 && <[Entity]List items={items} />}
```

## A slow render behind a fast input

```tsx
const [query, setQuery] = useState("")
const deferredQuery = useDeferredValue(query)

return (
  <>
    <SearchInput value={query} onChange={setQuery} />
    <[Entity]Results query={deferredQuery} />
  </>
)
```

The input re-renders with every keystroke at full priority; the expensive list renders with
the deferred value and is interrupted when the next keystroke arrives. A request per keystroke
is a different problem: the query key carries `deferredQuery` or a debounced value.

## Hidden but kept: `<Activity>`

```tsx
{tab === "details" && <[Entity]Details />}
```

Switching tabs unmounts the panel and throws away what the user typed. `<Activity>` (React 19.2)
hides it and keeps its state:

```tsx
<Activity mode={tab === "details" ? "visible" : "hidden"}>
  <[Entity]Details />
</Activity>
```

A hidden activity unmounts its effects (subscriptions, timers) and renders its updates at the
lowest priority; it mounts them again when it becomes visible. Use it for tabs, steps and
panels the user returns to, and to pre-render the screen they are likely to open next. A panel
whose state should reset when it closes keeps the plain condition.

## Lazy initializer, functional update

```tsx
const [draft, setDraft] = useState(() => parseDraft(storage.get(key)))
const increment = () => setCount((count) => count + 1)
```

`useState(parseDraft(…))` runs the parse every render and keeps the first result. A `setCount
(count + 1)` called twice in one handler increments once.

## Context: split churn from stable

```tsx
const SessionContext = createContext<ISession | null>(null)
const SessionActionsContext = createContext<ISessionActions | null>(null)

<SessionContext value={session}>
  <SessionActionsContext value={actions}>{children}</SessionActionsContext>
</SessionContext>
```

A consumer that only needs `actions` no longer re-renders on every session refresh. Before
adding a context at all, pass the subtree as `children` — most prop drilling disappears.

```tsx
const session = use(SessionContext)
```

`use` may sit behind a condition or an early return; `useContext` may not.

## APIs the Compiler skips

Some library APIs return values the Compiler cannot track, and it skips memoizing the component
that uses them; the `incompatible-library` lint names them. In this stack: React Hook Form's
`form.watch()` (read a value with `useWatch`, the `react-hook-form-zod` skill) and TanStack
Table's `useReactTable`. Keep such a call in the smallest component that needs it, so the rest
of the tree stays compiled.

## Versions

Check `package.json` once in the session before using an API from this table.

| API | Needs | Before it |
|---|---|---|
| `ref` as a plain prop | 19.0 | `forwardRef` |
| `<Context value>` | 19.0 | `<Context.Provider value>` |
| `use(Context)`, conditional allowed | 19.0 | `useContext`, top level only |
| `<title>`, `<meta>`, `<link>` rendered anywhere, hoisted to `<head>` | 19.0 | a head manager |
| `useEffectEvent` | 19.2 | a ref holding the latest value |
| `<Activity>` | 19.2 | a condition that unmounts, or CSS that hides while effects keep running |
| `<ViewTransition>`, `addTransitionType` | 19.3 | an animation library around enter and exit |
| `ref` on `<Fragment>` | 19.3 | a wrapper `div` for the ref |

In any version, no blanket `memo` around components.

## Animating with `<ViewTransition>` (19.3)

```tsx
<ViewTransition>
  <[Entity]Card item={item} />
</ViewTransition>
```

It animates an element entering, leaving, moving or resizing through the browser's View
Transition API, with a cross-fade by default. It runs only for updates inside
`startTransition`, a `<Suspense>` reveal or a `useDeferredValue` update; a plain `setState`
does not animate. `addTransitionType("next")` inside `startTransition` lets the same update
animate differently by its cause:

```tsx
startTransition(() => {
  addTransitionType("next")
  setSlide((slide) => slide + 1)
})

<ViewTransition enter={{ next: "from-right", previous: "from-left" }}>
  <Slide index={slide} />
</ViewTransition>
```

Around a `<Suspense>`, `<ViewTransition update="auto" default="none">` shows the fallback at
once and animates only its replacement by the content. Use it where the project already
animates; it does not replace a design-system transition the components carry.

## A ref on `<Fragment>` (19.3)

```tsx
const groupRef = useRef<FragmentInstance>(null)

<Fragment ref={groupRef}>
  {children}
</Fragment>
```

The instance acts on the children as a group without a wrapper element: `focus`/`focusLast`,
`addEventListener`, `observeUsing` for an `IntersectionObserver` or `ResizeObserver`,
`getClientRects`, `scrollIntoView`. It is a limited set of DOM methods, not a DOM element.
