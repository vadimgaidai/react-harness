# Effects you do not need

> Which `useEffect` is not needed, and what replaces it? Every shape here is the same defect: an
> effect doing work that belongs in render, a handler, the query cache or a subscription
> primitive. Each pair shows the effect and what replaces it.

## Derived state

```tsx
const [fullName, setFullName] = useState("")
useEffect(() => {
  setFullName(`${first} ${last}`)
}, [first, last])
```

Two renders per change and a frame where `fullName` is stale. Compute it:

```tsx
const fullName = `${first} ${last}`
```

If it is expensive, `useMemo` — still render, never state.

## Syncing a prop into state

```tsx
const [draft, setDraft] = useState(comment.body)
useEffect(() => {
  setDraft(comment.body)
}, [comment.body])
```

Either the prop is the value — read it — or the component owns a draft that should reset when
the entity changes, which is what `key` is for:

```tsx
<CommentEditor key={comment.id} comment={comment} />
```

## Keeping the previous value

A component that renders the old value beside the new one (a cross-fade, a "changed from"
label) tracks it as state adjusted during render, not with an effect and not with a ref
written while rendering:

```tsx
const [current, setCurrent] = useState(value)
const [previous, setPrevious] = useState(value)

if (value !== current) {
  setPrevious(current)
  setCurrent(value)
}
```

Setting the component's own state during render, behind a comparison that stops the next
pass, is the one write render allows: React discards the output and renders again before
painting, so there is no stale frame. An effect would paint the old value first; a ref written
during render breaks render purity and is not seen by the Compiler.

## An event's side effect

```tsx
useEffect(() => {
  if (submitted) {
    toast.success(t("[entity].saved"))
  }
}, [submitted])
```

It happened because the user clicked, so it lives where the click is handled, in `mutate`'s
per-call callback so the shared options' own `onSuccess` still runs (`tanstack-query` skill):

```tsx
mutate(values, {
  onSuccess: () => toast.success(t("[entity].saved")),
})
```

## An event fired from an effect

The effect reconnects whenever `theme` changes, although only the notification reads it:

```tsx
useEffect(() => {
  const connection = createConnection(roomId)
  connection.on("connected", () => {
    showNotification(t("chat.connected"), theme)
  })
  connection.connect()

  return () => connection.disconnect()
}, [roomId, theme])
```

The notification is an event that happens to fire from the effect. `useEffectEvent` (React
19.2) reads the latest `theme` and is not a dependency:

```tsx
const onConnected = useEffectEvent(() => {
  showNotification(t("chat.connected"), theme)
})

useEffect(() => {
  const connection = createConnection(roomId)
  connection.on("connected", () => {
    onConnected()
  })
  connection.connect()

  return () => connection.disconnect()
}, [roomId])
```

It replaces the two older workarounds: a ref that holds the latest value, and a dependency left
out behind `// eslint-disable-next-line react-hooks/exhaustive-deps`, which reads a stale
`theme`. An Effect Event is declared in the same component or hook as its effect, is never put
in a dependency array, and is not a way to silence the linter: a value the effect really
reacts to stays a dependency.

## Calling `onChange` when state changes

```tsx
useEffect(() => {
  onChange(value)
}, [value, onChange])
```

Fires on mount with the initial value and once more per render where `onChange` is a new
closure. Call it in the handler that changes the value:

```tsx
const updateSearch = (next: string) => {
  setValue(next)
  onChange(next)
}
```

## Fetching

```tsx
useEffect(() => {
  [entity]Api.getById(id).then(setItem)
}, [id])
```

No cancellation, no cache, a race when `id` changes mid-flight. The cache owns it:

```tsx
const { data: item } = useQuery([entity]Queries.byId(id))
```

## Mirroring server data into state

```tsx
const { data } = useQuery([entity]Queries.list(filters))
const [items, setItems] = useState<I[Entity][]>([])
useEffect(() => {
  if (data) {
    setItems(data)
  }
}, [data])
```

Two sources of truth that drift on the first invalidation. Read `data`; derive with `select`
when the shape differs (`tanstack-query` skill).

## Initializing on mount

```tsx
const [config, setConfig] = useState<IConfig | null>(null)
useEffect(() => {
  setConfig(buildConfig(props))
}, [])
```

A lazy initializer runs once and has no null frame:

```tsx
const [config] = useState(() => buildConfig(props))
```

## Chained effects

```tsx
useEffect(() => {
  setTotal(items.reduce(sum, 0))
}, [items])

useEffect(() => {
  setIsFree(total === 0)
}, [total])

useEffect(() => {
  if (isFree) {
    setShipping(null)
  }
}, [isFree])
```

Three renders to reach a value render could produce in one. Compute the chain, or make the
one event that starts it set everything:

```tsx
const total = items.reduce(sum, 0)
const isFree = total === 0
const shipping = isFree ? null : quote
```

## Analytics on mount

```tsx
useEffect(() => {
  track("article_viewed", { id })
}, [id])
```

Fires twice in StrictMode and again on every remount. Route-level views belong to the router's
navigation hook; interaction events belong to the handler that caused them.

## Subscribing to a store

```tsx
const [online, setOnline] = useState(navigator.onLine)
useEffect(() => {
  const goOnline = () => setOnline(true)
  const goOffline = () => setOnline(false)
  window.addEventListener("online", goOnline)
  window.addEventListener("offline", goOffline)

  return () => {
    window.removeEventListener("online", goOnline)
    window.removeEventListener("offline", goOffline)
  }
}, [])
```

`useSyncExternalStore` handles subscribe, snapshot and tearing:

```tsx
const online = useSyncExternalStore(subscribeToNetwork, () => navigator.onLine)
```

## What is left for an effect

Syncing with something React does not own — a third-party widget's instance, a `WebSocket`,
`document.title` where the `<title>` element cannot reach, an `IntersectionObserver`. Each
returns a cleanup.
