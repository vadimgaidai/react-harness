---
name: routing
description: URL state and route loading for React Router (v7/v8, data or declarative mode) and TanStack Router — which router the project has, search params parsed through a schema, a use-*-filters hook with a patch setter, a loader that fills the TanStack Query cache, route params, pending and error UI, preloading, auth guards, nested routes. Use when code touches useSearchParams, setSearchParams, useNavigate, useNavigation, useParams, a loader, loaderDeps, validateSearch, useSearch, beforeLoad, errorElement or errorComponent, pendingComponent, createBrowserRouter or createRouter, Route or Outlet, a query string, or a use-*-filters / use-*-sort hook; when filters, sort or pagination should survive a reload, a shared link or the Back button; or when reviewing any of these.
---

# Routing

- Read `package.json` once: `react-router` (v7/v8; data mode when routes go through `createBrowserRouter`, declarative when only `<Routes>`) or `@tanstack/react-router`. The rules below hold for both; the router's own API is in its reference file, and its version decides the names.
- Filters, sort and page live in the URL and are read from it on every render, never copied into `useState`, so a reload, a shared link and Back/Forward all show the same screen.
- Search params are parsed once, at the router, through a Zod schema with a fallback per field (`.catch(...)`), into a typed object; no `searchParams.get("x") as T` downstream (`typescript`, narrow at the boundary).
- One hook per screen owns its URL state, `use[Entity]Filters()` returning `[filters, setFilters]`; the setter takes a patch (`code-shape`), merges it over the current params, and resets `page` in the same write when a filter changes.
- A value equal to its default is not written to the URL: the param is deleted, so a shared link carries only what the user chose; a param name or on-value read back is one named constant (`code-shape`).
- The query key is built from the parsed filters, and the route and its component use the same `queryOptions` from the entity's factory (`tanstack-query`).
- A loader fills the query cache and returns nothing the component keeps; the component reads the same options with `useSuspenseQuery`, so its data is present and the route owns the pending and error states. A loader's copy read with `useLoaderData` is a second source of truth.
- A loader depends only on the inputs it fetches with: route params, and the search fields its query key uses (TanStack Router's `loaderDeps`), never the whole search object, or every unrelated param change reloads it.
- Route params are parsed like search params, once, at the route; no `params.id as string`.
- The `QueryClient` reaches loaders through the router (TanStack Router's context, a loader factory in React Router), never an import of a second client.
- Pending and error come from the router: TanStack Router's `pendingComponent` and `errorComponent`, React Router's `useNavigation()` and `errorElement`; never an `isNavigating` flag in component state. The error UI's retry resets the query error and reloads the route.
- A nested route owns its loading boundary: a child's fetch never blanks the parent's already-rendered layout.
- Navigation targets are typed: TanStack Router's `to` with `params` is checked by the compiler, React Router paths come from one `paths` object, never a string built at the call site.
- An auth guard runs before the route loads (TanStack Router's `beforeLoad` throwing `redirect`, React Router v8 middleware), never in a component effect that calls `navigate`.
- Data a route mutates goes through a TanStack Query mutation and a React Hook Form submit (`react-hook-form-zod`), never a router `action` or `<Form>`, so the cache stays the one owner of server data.
- Where route files go: the structure skill loaded in this project.

## Example

Filter state copied into `useState` stops at the value it had on mount, so Back changes the URL and leaves the list as it was:

```tsx
const [searchParams] = useSearchParams()
const [status, setStatus] = useState(searchParams.get("status") ?? "all")
```

The filters come from the screen's hook, parsed from the URL on every render, and the query key is built from them:

```tsx
const [filters, setFilters] = use[Entity]Filters()
const { data } = useSuspenseQuery([entity]Queries.list(filters))
```

## References

- [references/search-params.md](references/search-params.md): writing or reviewing a `use-*-filters` or `use-*-sort` hook, its schema, defaults kept out of the URL, or a paginated list restored from the URL, in either router.
- [references/react-router.md](references/react-router.md): a React Router project: the router, a loader with the query cache, params, pending and error, middleware, declarative mode.
- [references/tanstack-router.md](references/tanstack-router.md): a TanStack Router project: router context, `validateSearch`, `loaderDeps`, a loader with the query cache, pending and error, preloading, `beforeLoad`.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
