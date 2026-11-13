# Code shapes

Answers: where exactly does a `code-shape` rule stop, and what does the shape it reports
look like next to the shape that replaces it? Open the one section a doubt or a finding
needs; each section is named after its rule, and `review` and other skills cite them as
`code-shape §<section>`.

One pair per rule: the shape that gets reported, then the shape that replaces it.
Placeholders (`[entity]`, `[Entity]`, `I[Entity]`) stand for real names. Every replacement
returns the same values as the original for the same inputs; where that needs a condition,
the condition is stated next to the pair.

Sections: The least code · Comments · Two parameters · Guard clauses · A return is a block ·
Ternaries ·
Collections by meaning · Explicit returns · Boolean parameters · A setter takes a patch ·
Names · The name covers the behaviour · Extract for a name, not for size · A pure helper
beside a hook · Magic numbers and boundary literals.

## The least code

Reuse the primitive, library call or idiom that already exists before writing one. What
goes: a wrapper that only forwards a call, a re-export that only renames, a variable that
only repeats the expression `return`ed on the next line, a default branch for a state the
input is guaranteed never to hold, a parameter nothing passes yet. A single use does not
make a variable redundant, and a wrapper that owns a boundary (the API module, the adapter
around a dependency) stays. A diff well past its sibling's size for the same role is a
reason to look for these, not a finding by itself.

```ts
export const get[Entity]ById = (id: string) => [entity]Api.getById(id)
export { formatDate as formatCreatedAt } from "@/shared/lib/format"
const result = items.filter(isActive)
return result
```

The wrapper only forwards, the re-export only renames, the variable only repeats the expression
returned on the next line. Call `[entity]Api.getById` directly, import `formatDate` under its
own name, return the expression.

```ts
const toKebab = (name: string) => {
  if (name === "index") {
    return name
  }

  return name.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase()
}
```

`"index"` has no capital to replace, so the code after the check already returns it unchanged;
the check goes. A check stays when removing it changes a result for some input.

What stays: `[entity]Api` itself (the boundary around `http`), a variable whose name says what
the expression means at this spot (`const isOwner = user.id === [entity].authorId` used once
is fine), a re-export that forms a module's public surface.

```ts
switch (status) {
  case "draft":
    return t("[entity].status.draft")
  case "published":
    return t("[entity].status.published")
  default:
    return t("[entity].status.unknown")
}
```

`status` is a two-member union, so the `default` goes — but only when the value is guaranteed
to be in the union: produced in this codebase, or parsed at the boundary (`zod` schema,
exhaustive check in the mapper). A type annotation on a value read from the API, the URL or
storage is a promise, not a guarantee; there the `default` is the guard and stays. Same for
`?? fallback` on a field — remove it with the schema that makes it unreachable, not with the
type alone. Replace the branch with the `never` check from `typescript` §Exhaustive `switch`, so a
member added later fails the build instead of reaching a fallback.

## Comments

Code carries no comments. Two marks are allowed: `// TODO: <what is left>` for work decided
to be done later, and `// ! <note>` for important logic a reader must not break or "clean up".
JSDoc that restates the signature, banner lines (`// ===== Helpers =====`) and "for now" notes
are comments too.
A tool directive with its reason (`eslint-disable`, `@ts-expect-error`) is not a comment and
stays. Restating the line, step narration and section headers like `// Handle errors` go.

```ts
/**
 * Formats the amount.
 * @param value - the amount
 */
const formatAmount = (value: number) => …

// Calculate the badge size based on the count
const badgeSize = count > 99 ? "lg" : "sm"

// Handle errors
if (error) {
  return <ErrorState />
}

// TODO: drop the cap once the API paginates
const visible = items.slice(0, 50)

// ! Safari fires blur before click; keep the timeout
const timeout = setTimeout(close, 0)
```

The JSDoc and the first comment say what the signature and the line say. The second is a section header for a block that already
reads. The third names deferred work. The fourth names a constraint a reader would otherwise
"clean up". Only the last two survive.

## Two parameters

The ceiling applies to functions of ours. An external API's signature and a callback whose
signature a library sets (`map`, `reduce`, an event handler, a resolver) keep their shape:
`items.reduce((sum, item, index) => …, 0)` is not a third parameter to report.

The first parameter, the value the function is about, stays positional; the rest go into one
typed options object.

```ts
const submit = (articleId: string, body: string, onDone: () => void) => …
submit(id, text, refresh)
```

```ts
interface ISubmitOptions {
  body: string
  onDone: () => void
}

const submit = (articleId: string, { body, onDone }: ISubmitOptions) => …
submit(id, { body: text, onDone: refresh })
```

The call site reads, the order of the options stops mattering, an optional field stops being an
`undefined` placeholder in the middle.

## Guard clauses

Exit cases return at the top and the happy path stays unindented. Nesting past two levels
inverts the conditions first; extract only when the inner block is an operation with a name.

```ts
const canEdit = (user: IUser | null, [entity]: I[Entity]) => {
  if (user) {
    if ([entity].authorId === user.id) {
      if (![entity].isLocked) {
        return true
      }
    }
  }

  return false
}
```

```ts
const canEdit = (user: IUser | null, [entity]: I[Entity]): boolean => {
  if (!user) {
    return false
  }

  if ([entity].authorId !== user.id) {
    return false
  }

  return ![entity].isLocked
}
```

Inverting flattens the depth without a new function. Extract instead when the innermost block
is an operation with its own name — then the function is kept for the name, not for the depth.

## A return is a block

A `return` sits on its own line inside braces, never `if (x) return y` on one line. The same
holds for any single-statement `if`.

```ts
if (!user) return null
if (isDirty) save()
```

```ts
if (!user) {
  return null
}

if (isDirty) {
  save()
}
```

## Ternaries

A ternary picks between two values. It never picks between behaviours (two calls with side
effects) and never nests: a second condition becomes a named boolean, a named value, a
lookup map or a sub-component.

```tsx
const labelKey = isOwner
  ? isLocked
    ? "[entity].actions.locked"
    : "[entity].actions.edit"
  : isAdmin
    ? "[entity].actions.moderate"
    : "[entity].actions.view"
```

```tsx
const ownerKey = isLocked ? "[entity].actions.locked" : "[entity].actions.edit"
const otherKey = isAdmin ? "[entity].actions.moderate" : "[entity].actions.view"
const labelKey = isOwner ? ownerKey : otherKey
```

Same inputs, same priority: `isOwner` wins, `isLocked` only matters for the owner, `isAdmin`
only for non-owners. Each ternary now picks between two values, and the two named values are
single-use variables that earn their line.

```tsx
isPending ? <Spinner /> : error ? <ErrorState /> : <[Entity]List items={data} />
```

Three render branches are early returns, not a ternary chain:

```tsx
if (isPending) {
  return <Spinner />
}

if (error) {
  return <ErrorState />
}

return <[Entity]List items={data} />
```

## Collections by meaning

`map`/`filter`/`find`/`some`/`every` where they say the operation and keep behaviour; a
loop that reads is not rewritten. What goes is repeated work: a search over one collection
repeated for each element of another, a value recomputed per iteration, an intermediate
array nobody reads. A `Map`/`Set` or a value computed once replaces it when the task
warrants, with order, duplicates, missing values and side effects checked (`find` returns
the first match; filling a `Map` keeps the last). `map` with `find` inside, or the inner
loop moved into a helper, is the same repetition. A task that must visit every pair keeps
its nested traversal.

```ts
for (const comment of comments) {
  const author = users.find((user) => user.id === comment.authorId)
  …
}
```

```ts
const userById = new Map(users.map((user) => [user.id, user]))
for (const comment of comments) {
  const author = userById.get(comment.authorId)
  …
}
```

The inner scan is n×m; the lookup is built once. Equivalent when `user.id` is unique (`find`
returns the first match, `Map` keeps the last), `users` does not change during the loop, and
the missing case is `undefined` on both sides. With duplicate ids, dedupe first or keep
`find`. Writing it as `comments.map((comment) => users.find(…))` or moving the `find` into
`getAuthor(comment)` changes nothing about the algorithm.

```ts
const activeIds = items.filter(isActive).map((item) => item.id)
const activeCount = items.filter(isActive).length
const hasActive = items.filter(isActive).length > 0
```

```ts
const activeItems = items.filter(isActive)
const activeIds = activeItems.map((item) => item.id)
const activeCount = activeItems.length
const hasActive = items.some(isActive)
```

The same filter ran three times; once is enough, and `some` stops at the first match where
`filter(...).length > 0` walks the whole list. Equivalent when `isActive` has no side
effects — a predicate that counts or logs runs a different number of times after the change.

```ts
for (const a of points) {
  for (const b of points) {
    if (distance(a, b) < limit) {
      pairs.push([a, b])
    }
  }
}
```

Every pair is the task; the nested traversal stays. A loop is a finding only when it repeats
work the task does not need.

## Explicit returns

Implicit arrow returns are for one expression. A branching body writes the value in every
`return` and annotates the return type.

```ts
const parsePage = (raw: string | null) => {
  if (raw === null) {
    return
  }

  const page = Number(raw)

  if (Number.isNaN(page)) {
    return 1
  }

  return page
}
```

The body branches, one branch returns bare, and the type `number | undefined` is inferred
rather than stated. Write the value in every branch and the type on the signature; the
contract does not move:

```ts
const parsePage = (raw: string | null): number | undefined => {
  if (raw === null) {
    return undefined
  }

  const page = Number(raw)

  return Number.isNaN(page) ? 1 : page
}
```

`null` → `undefined`, `"abc"` → `1`, `""` → `0`, `"0"` → `0`, `"-3"` → `-3`, exactly as before.
Changing what the function returns for `""` or a negative page is a contract change and its
own finding, not a shape fix.

## Boolean parameters

```ts
formatAmount(total, true)
```

```ts
formatAmount(total, { withCurrency: true })
```

Or two functions: `formatAmount` and `formatPrice`. The call site `(x, true)` tells a reader
nothing.

## A setter takes a patch

```ts
const writeFilters = (filters: I[Entity]Filters) => …
writeFilters({ ...filters, status })
writeFilters({ ...filters, page: filters.page + 1 })
```

```ts
const setFilters = (patch: Partial<I[Entity]Filters>) => …
setFilters({ status })
setFilters({ page: filters.page + 1 })
```

Adding `sort` to the filters touches the setter and nothing else; with the whole-state
shape every call site re-spreads fields it does not change, and a call that forgets the
spread silently resets them. Same values written for the same inputs: the setter merges
the patch over the current state. A hook that keeps the filters in the URL is this shape
over `useSearchParams` — [routing/references/search-params.md](../../routing/references/search-params.md),
including the variant where a filter's off value (`archived: false`, `tags: []`) means
*no param*.

## Names

```ts
const data = await [entity]Api.getList()
const flag = user.id === [entity].authorId
const handleClick = () => mutate(values)
class [Entity]Manager {}
const formatDate2 = …
```

```ts
const [entity]s = await [entity]Api.getList()
const isOwner = user.id === [entity].authorId
const submit[Entity] = () => mutate(values)
const formatShortDate = …
```

A name carries the domain word; the type is already in the type. `Manager`, `Helper`, `Utils`
and `Service` are the absence of a name. A `2` means the author did not grep.

## The name covers the behaviour

`parse*`, `get*`, `format*` promise one operation. A body that also sorts, dedupes in a way
callers rely on, or caches either loses the extra behaviour or gets a name that says it.

```ts
const parseTags = (raw: string | null): Array<string> =>
  (raw ?? "").split(",").filter(Boolean).sort()
```

```ts
const parseTags = (raw: string | null): Array<string> =>
  (raw ?? "").split(",").filter(Boolean)

const queryKey = [entity]Keys.list({ ...filters, tags: [...filters.tags].sort() })
```

A reader of `parseTags` expects the param's values back; the `.sort()` reorders them, and
every caller that renders the list inherits an order the input never had. The sort moves to
the one place that needs a canonical order — the query key, so `?tags=b,a` and `?tags=a,b`
share a cache entry — on a local copy. When the ordering *is* the point for every caller,
the name says so: `parseSortedTags`. Same for a `get*` that caches or a `format*` that also
trims: the name tells the whole story or the body does less.

## Extract for a name, not for size

A function earns its place by naming an operation or owning a responsibility (a hook owns
its state), one caller or ten. A chunk that only forwards, or was cut out to shorten the
parent, is inlined.

```ts
const buildQueryKey = (filters: I[Entity]Filters) => [entity]Keys.list(filters)
const { data } = useQuery({ queryKey: buildQueryKey(filters), … })
```

The function only forwards to `[entity]Keys.list`, so the name adds nothing the callee's name
does not say. Inline it.

```ts
const toListRow = ([entity]: I[Entity]): I[Entity]Row => ({
  id: [entity].id,
  title: [entity].title,
  authorName: [entity].author.displayName,
  updatedAt: formatDate([entity].updatedAt),
})

const rows = [entity]s.map(toListRow)
```

One caller too, and it stays: `toListRow` names an operation the `map` call would otherwise
spell out inline. The test is whether the name tells the reader something, not how many
callers there are or how long the parent is.

## A pure helper beside a hook

In `use-[entity]-filters.ts`:

```ts
const parseTags = (raw: string | null): Array<[Entity]Tag> =>
  (raw ?? "").split(",").filter(is[Entity]Tag)

const toTagsParam = (tags: Array<[Entity]Tag>): string | undefined =>
  tags.length > 0 ? tags.join(",") : undefined

export const use[Entity]Filters = () => { … }
```

`parseTags` and `toTagsParam` use no React, carry names a reader looks up, and are the part
of the hook a test would want without rendering anything. They move to where the
structure skill loaded in this project puts a module's pure functions, and the hook imports
them. The hook file keeps what owns React state.

What stays inline: a one-expression mapping used once (`const page = Number(raw ?? 1)`), an
arrow the hook's own `useMemo` wraps. The rule is about a helper that is pure *and* named
*and* more than one expression — not about every arrow above a hook.

## Magic numbers and boundary literals

```ts
const isTooLong = body.length > 2000
setTimeout(save, 500)
```

```ts
const COMMENT_MAX_LENGTH = 2000
const AUTOSAVE_DELAY_MS = 500
```

A number with a domain meaning gets the domain's name; when a second file needs it, it goes
where the structure skill puts shared constants. `0`, `1` and an array index are not magic.

```ts
const isArchived = searchParams.get("archived") === "true"
next.set("archived", "true")
const draft = localStorage.getItem("[entity]-draft")
```

```ts
const ARCHIVED_PARAM = "archived"
const PARAM_ON = "true"
const [ENTITY]_DRAFT_KEY = "[entity]-draft"
```

A string that another side reads back — a search-param name or value, a storage key, a
header, a discriminator in the URL — is a protocol, and the two sites that must agree on
it agree through one name. Not every string: a translation key, a `className`, an `as
const` member, a label passed within the code's own calls carries its meaning in place and
stays a literal.
