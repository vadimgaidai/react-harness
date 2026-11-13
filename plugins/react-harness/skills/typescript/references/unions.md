# How is a value with states, or with a known set of values, typed?

## Discriminated unions over optional fields

```ts
type TUploadState = { isLoading?: boolean; data?: IUpload; error?: Error }
```

```ts
type TUploadState =
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "success"; data: IUpload }
```

The optional version lets invalid states be
built (loading with data and an error at once) and makes every reader check fields the
status already decides.

The same goes for two booleans where one state was meant, an optional field that is required
in every real case, and a string whose set of values is known. An invariant held only in a
comment or a runtime check belongs in the type when the type can carry it.

## Exhaustive `switch`

A `switch` on a union handles every member. With a `never` check in `default`, a member
added later fails the build instead of falling through:

```ts
const isUploadSettled = (state: TUploadState): boolean => {
  switch (state.status) {
    case "loading": {
      return false
    }
    case "error":
    case "success": {
      return true
    }
    default: {
      const unhandled: never = state
      return unhandled
    }
  }
}
```

## Const-derived unions: a known set of values lives in one constant

A prop like `size` is not typed `"sm" | "md" | "lg"` inline. The set is a constant and the
type is derived from it, so there is one place to add a value and the runtime list
(options, iteration, validation) and the type cannot drift apart:

```ts
export const BUTTON_SIZES = ["sm", "md", "lg"] as const
export type TButtonSize = (typeof BUTTON_SIZES)[number]
```

The same holds for a `variant`, a `status`, a `Record` key — any string whose set of values
is known. An inline union is the typed-string version of a magic string.

## No `enum`

An `as const` object or array plus a derived union replaces it:

```ts
export const ORDER_STATUS = { pending: "pending", shipped: "shipped" } as const
export type TOrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS]
```

The structure skills own which file the constant lives in.
