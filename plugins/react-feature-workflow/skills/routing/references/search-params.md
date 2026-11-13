# Search params: one schema, one hook, restored on load

How does a screen keep filters, sort and page in the URL so that a reload, a shared link and Back/Forward all show the same screen, one change never drops the other params, and defaults stay out of the link, in React Router and in TanStack Router?

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`, `[ENTITY]`) with real names. Which router the project has: `package.json`, once per session.

## The URL is the source of truth

Filters, sort and pagination are restored from the URL on load, so a shared link opens the
same screen the sender saw. State derived from the URL is read from it on every render, not
copied into `useState` once on mount: a copy stops tracking Back and Forward, and the browser
changes the URL while the screen keeps the old value.

## One schema for the screen's URL state

The schema is the boundary: the URL is untrusted input, and everything past the schema is
typed (`typescript`, narrow at the boundary). Every field has a fallback with `.catch()`, so a
hand-edited or outdated link opens the screen with the default instead of an error, and the
defaults come out of the same schema:

```typescript
export const [ENTITY]_STATUSES = ["all", "open", "closed"] as const

export const [entity]FiltersSchema = z.object({
  status: z.enum([ENTITY]_STATUSES).catch("all"),
  page: z.coerce.number().int().min(1).catch(1),
  tags: z.array(z.enum([ENTITY]_TAGS)).catch([]),
  archived: z.boolean().catch(false),
})

export type T[Entity]Filters = z.infer<typeof [entity]FiltersSchema>

export const [ENTITY]_FILTER_DEFAULTS = [entity]FiltersSchema.parse({})
```

This is not a form schema, so the `react-hook-form-zod` rule against `z.coerce` does not apply:
nothing types a form against it. `z.coerce` turns React Router's string `"2"` into `2`;
TanStack Router already hands the schema a number. `tags` is a known set, so the schema
filters it against the const-derived union (`typescript` §Const-derived unions).

## A hook that merges, never replaces

The screen's components read and write the URL through one hook. Its setter takes a patch of
the fields that change (`code-shape` §A setter takes a patch), merges it over the current
filters, and resets `page` to `1` in the same write, since a new filter makes the old page
meaningless; a patch that sets `page` itself wins over the reset.

React Router:

```tsx
const PARAM_ON = "1"

const readFilters = (searchParams: URLSearchParams): T[Entity]Filters =>
  [entity]FiltersSchema.parse({
    status: searchParams.get("status") ?? undefined,
    page: searchParams.get("page") ?? undefined,
    tags: searchParams.get("tags")?.split(","),
    archived: searchParams.get("archived") === PARAM_ON,
  })

const toParams = ({ status, page, tags, archived }: T[Entity]Filters) => ({
  status: status === [ENTITY]_FILTER_DEFAULTS.status ? undefined : status,
  page: page === [ENTITY]_FILTER_DEFAULTS.page ? undefined : String(page),
  tags: tags.length > 0 ? tags.join(",") : undefined,
  archived: archived ? PARAM_ON : undefined,
})

export const use[Entity]Filters = () => {
  const [searchParams, setSearchParams] = useSearchParams()
  const filters = readFilters(searchParams)

  const setFilters = (patch: Partial<T[Entity]Filters>) => {
    setSearchParams((previous) => {
      const next = new URLSearchParams(previous)
      const params = toParams({ ...readFilters(previous), page: 1, ...patch })

      for (const [key, value] of Object.entries(params)) {
        if (value === undefined) {
          next.delete(key)
          continue
        }

        next.set(key, value)
      }

      return next
    })
  }

  return [filters, setFilters] as const
}
```

`setSearchParams((previous) => ...)` starts from the current params, so a param this hook does
not own (a `tab`, an open dialog) survives; a plain object (`setSearchParams({ status })`)
replaces the whole query string. A value equal to its default maps to `undefined` and deletes
its param, so the link carries only what the user chose. `PARAM_ON` is the one string the
reader and the writer agree on (`code-shape` §Magic numbers and boundary literals); the
schema's field names are the param names. `readFilters` and `toParams` are pure and live
where the structure skill puts a module's pure functions (`code-shape` §A pure helper beside a
hook).

TanStack Router: the route validates the search and strips defaults, so the hook only reads
and patches:

```tsx
export const Route = createFileRoute("/[entity]s/")({
  validateSearch: [entity]FiltersSchema,
  search: { middlewares: [stripSearchParams([ENTITY]_FILTER_DEFAULTS)] },
})
```

```tsx
const [entity]ListRoute = getRouteApi("/[entity]s/")

export const use[Entity]Filters = () => {
  const filters = [entity]ListRoute.useSearch()
  const navigate = [entity]ListRoute.useNavigate()

  const setFilters = (patch: Partial<T[Entity]Filters>) => {
    navigate({ search: (previous) => ({ ...previous, page: 1, ...patch }) })
  }

  return [filters, setFilters] as const
}
```

`validateSearch` runs the schema on every navigation, so `filters` is typed and never holds an
invalid value. `stripSearchParams` drops every param equal to its default when the link is
built. `getRouteApi` gives the hook the route's typed API without importing the route file,
which keeps the route code-split. The search updater receives the current search, so other
params survive the same way. Zod 3 needs `zodValidator` and `fallback` from
`@tanstack/zod-adapter` instead of the bare schema ([tanstack-router.md](tanstack-router.md)).

## A paginated list restored from the URL

```tsx
const [filters, setFilters] = use[Entity]Filters()
const [isSwitching, startTransition] = useTransition()
const { data } = useSuspenseQuery([entity]Queries.list(filters))

const goToPage = (page: number) => {
  startTransition(() => {
    setFilters({ page })
  })
}
```

The setter runs in `startTransition`, so the current page stays on screen, dimmed on
`isSwitching`, while the next one loads (`tanstack-query` §Reads); a list that stays on
`useQuery` keeps it with `placeholderData: keepPreviousData` instead.

Reloading this URL, or opening it fresh from a shared link, reproduces the exact list the
sender saw: the query key is built from the same parsed `filters`, not from state that started
at a default and only later synced. On a route with a loader the component reads the loader's
inputs instead ([tanstack-router.md](tanstack-router.md), `useLoaderDeps`), so both use one key.
