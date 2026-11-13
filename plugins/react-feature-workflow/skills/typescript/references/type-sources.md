# Where does a type come from, and how is a literal checked without widening it?

## Types come from the contract and from inference

A hand-written interface that mirrors `z.infer<typeof schema>` or a contract shape is a
second source of truth: the two drift, and the compiler checks only one. Derive the type
from the schema or the contract, and let inference type locals and single-expression return values;
a branching function states its return type (`code-shape` §Explicit returns).

## `satisfies` for shape-checking a literal without widening it

An annotation replaces the literal's type with the annotated one: keys become `string`,
values widen, and a typo on a key compiles. `satisfies` checks the same shape and keeps
the literal's own type.

```ts
const ROUTES = { home: "/", settings: "/settings" } satisfies Record<string, `/${string}`>
```

`ROUTES.settings` keeps the type `"/settings"` and `ROUTES.setings` is an error; with `const ROUTES: Record<string, string>` both compile as `string`.

## Naming: `I` for an interface, `T` for a type

An object shape is an `interface` and its name starts with `I`: `IUpload`, `I[Entity]`,
`IFormatAmountOptions`. A union, a derived type or a mapped type is a `type` and its name
starts with `T`: `TUploadState`, `TPaymentMethod`, `T[Feature]FormValues`. The prefix tells
the reader which of the two it is at the import, without opening the file.

```ts
type Upload = { id: string; name: string }
interface UploadState { status: "loading" | "success" }
```

```ts
interface IUpload {
  id: string
  name: string
}

type TUploadState = { status: "loading" } | { status: "success"; data: IUpload }
```

## Type-only imports are `import type`

An import used only as a type is `import type`, so it is erased from the build and cannot
pull a module in at runtime.

## Generic parameter names

Generic parameters stay `T`, `K`, `TData` — a descriptive name on a generic parameter is
noise the call site never reads.
