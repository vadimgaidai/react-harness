# Code splitting, Suspense and error boundaries

> What gets loaded lazily, where do Suspense and error boundaries go, and how does a retry
> actually retry? Replace the placeholders (`[entity]`, `[Entity]`) with real names.

## What to split

Lazy: routes, the content of modals, drawers and popovers, heavy third-party widgets, anything
behind a tab, a wizard step or a permission check. Eager: anything above the fold, and any
component smaller than the request that would fetch it.

## Lazy route

```tsx
const [Entity]Page = lazy(() => import("@/pages/[entity]"))

<Route
  path={paths.[entity].list}
  element={
    <ErrorBoundary FallbackComponent={RouteError}>
      <Suspense fallback={<[Entity]PageSkeleton />}>
        <[Entity]Page />
      </Suspense>
    </ErrorBoundary>
  }
/>
```

One route's dependencies stop being everyone's download. The fallback is a skeleton the size
of the page, not a centered spinner — a spinner is a layout shift when the page arrives.

## Split the content, not the trigger

```tsx
const [Entity]EditorDialogContent = lazy(() => import("./[entity]-editor-dialog-content"))

export const [Entity]EditorDialog = () => {
  const [isOpen, setIsOpen] = useState(false)
  const preload = () => import("./[entity]-editor-dialog-content")

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button onMouseEnter={preload} onFocus={preload}>{t("actions.edit")}</Button>
      </DialogTrigger>
      <DialogContent>
        {isOpen && (
          <ErrorBoundary FallbackComponent={DialogError}>
            <Suspense fallback={<DialogSkeleton />}>
              <[Entity]EditorDialogContent />
            </Suspense>
          </ErrorBoundary>
        )}
      </DialogContent>
    </Dialog>
  )
}
```

The button stays eager; the editor, its schema and its rich-text dependency load on intent.
Prefetch the dialog's data on the same hover (`tanstack-query` skill, prefetch on intent).

## Heavy widget at the point of use

```tsx
const RevenueChart = lazy(() => import("./revenue-chart"))
```

Charts, editors, maps, date pickers, PDF viewers, drag-and-drop: each is an import inside the
component that renders it, never a top-level import of the page.

## Boundary placement

```tsx
<ErrorBoundary FallbackComponent={RegionError}>
  <Suspense fallback={<HeaderSkeleton />}>
    <[Entity]Header id={id} />
  </Suspense>
</ErrorBoundary>
<ErrorBoundary FallbackComponent={RegionError}>
  <Suspense fallback={<CommentsSkeleton />}>
    <[Entity]Comments id={id} />
  </Suspense>
</ErrorBoundary>
```

Each region that loads on its own gets its own boundary, so a slow comments query does not
blank the header. A single boundary at the root turns every chunk and every
`useSuspenseQuery` into a full-page fallback.

## Transition around a route swap

```tsx
const [isPending, startTransition] = useTransition()
const open = (id: string) => startTransition(() => navigate(paths.[entity].details(id)))
```

The current screen stays visible, dimmed on `isPending`, instead of flashing the fallback.
Preload the next route's chunk on hover or focus, the same way the dialog above does.

## Error boundary with a real retry

A query that throws and a chunk that fails to load need two different retries — plain
`resetErrorBoundary` only re-renders the boundary's children, it does not re-run either one.

### A query threw (`throwOnError`)

`QueryErrorResetBoundary`'s `reset` clears the flag that makes the query keep re-throwing the
same cached error, so the next render's `useQuery` call actually retries the fetch:

```tsx
const RouteError = ({ resetErrorBoundary }: FallbackProps) => {
  const { t } = useTranslation()

  return (
    <ErrorState
      title={t("errors.title")}
      action={<Button onClick={resetErrorBoundary}>{t("actions.retry")}</Button>}
    />
  )
}

<QueryErrorResetBoundary>
  {({ reset }) => (
    <ErrorBoundary FallbackComponent={RouteError} onReset={reset}>
      …
    </ErrorBoundary>
  )}
</QueryErrorResetBoundary>
```

Without `onReset={reset}`, `resetErrorBoundary` alone re-renders with the same query state,
which still holds the cached error, and the boundary throws again immediately.

### `QueryBoundary` — one component for every query-backed region

Every region that reads with `useSuspenseQuery` needs the same three wrappers, so they are one
domain-free component the structure skill places with the global components:

```tsx
interface IQueryBoundaryProps {
  fallback: ReactNode
  errorFallback: ComponentType<FallbackProps>
  children: ReactNode
}

export const QueryBoundary = ({ fallback, errorFallback, children }: IQueryBoundaryProps) => (
  <QueryErrorResetBoundary>
    {({ reset }) => (
      <ErrorBoundary FallbackComponent={errorFallback} onReset={reset}>
        <Suspense fallback={fallback}>{children}</Suspense>
      </ErrorBoundary>
    )}
  </QueryErrorResetBoundary>
)
```

The region passes its own skeleton and its own error fallback, so each failure says what
failed and retries only that region. `ErrorBoundary` and `FallbackProps` come from
`react-error-boundary`; a project without it gets the package named in the plan, never added
mid-implementation.

### A chunk failed to load (`lazy()`)

A chunk fetch fails after every deploy on a stale hashed filename; without a boundary the app
goes blank. `lazy()` caches the rejected import promise on that one component reference, so
`resetErrorBoundary` alone re-renders and re-throws the same cached rejection — it never
re-imports. The retry needs a fresh promise: a new `lazy()` reference, or a full reload of
the route.

```tsx
const ChunkError = () => {
  const { t } = useTranslation()

  return (
    <ErrorState
      title={t("errors.chunkLoadFailed")}
      action={
        <Button onClick={() => window.location.reload()}>{t("actions.retry")}</Button>
      }
    />
  )
}

<ErrorBoundary FallbackComponent={ChunkError} resetKeys={[location.pathname]}>
  <Suspense fallback={<[Entity]PageSkeleton />}>
    <[Entity]Page />
  </Suspense>
</ErrorBoundary>
```

`resetKeys` recovers the boundary automatically on a route change, which is enough once the
deploy that broke the old chunk has finished; the reload button is the immediate escape hatch
for a user already on the broken route.

Boundaries catch render-time throws. A rejected promise in a handler, a `setTimeout` or an
un-awaited call never reaches one; handle those where they happen.
