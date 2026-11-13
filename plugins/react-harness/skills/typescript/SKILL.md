---
name: typescript
description: Type discipline for .ts and .tsx files — where a type comes from, narrowing unknown input with a guard instead of an `as` cast, discriminated unions instead of optional fields, `satisfies`, `as const` instead of `enum`, `unknown` instead of `any`. Use whenever a .ts or .tsx file is written or reviewed, and whenever a task mentions a type, interface, generic, cast, `as`, `any`, `!`, `enum`, union, type guard, `z.infer` or `@ts-ignore`.
---

# TypeScript

- A type comes from the contract (`z.infer`, the contract's shape) or from inference; a hand-written interface that mirrors one is a second source of truth.
- Unknown input is narrowed once, where it enters (zod or a type guard); past that point there is no `as`, since a cast is a claim the compiler cannot check and a guard is one it can.
- A value with states is a discriminated union, not a bag of optional fields.
- A `switch` on a union handles every member, so a new member fails the build.
- `satisfies` checks a literal's shape without widening it; an annotation widens.
- No `enum`: an `as const` constant plus a union derived from it gives the same type with one list and no runtime quirks; the structure skill decides which file holds it.
- A known set of values (`size`, `variant`, `status`, a `Record` key) lives in one constant and its type is derived from it, never written as an inline string-literal union.
- `unknown` at the edge, never `any`: `any` switches the compiler off for everything it touches.
- No re-check of what a parsed or locally produced type guarantees: no runtime `typeof` it already settles, no `!`, no `?? fallback` on a value it says is present. An annotation on data from the API, the URL or storage is a promise: its guard goes only with the schema that parses it (`code-shape` §The least code).
- An object shape is an `interface` named with `I` (`IUpload`, `IFormatAmountOptions`); a union or a derived type is a `type` named with `T` (`TUploadState`, `TPaymentMethod`); generic parameters stay `T`, `K`, `TData`.
- Type-only imports are `import type`, so the build erases them and they cannot pull a module in at runtime.

## Example

A string from outside is narrowed with a guard over the constant, not cast:

```ts
const method = searchParams.get("method") as TPaymentMethod
```

```ts
export const PAYMENT_METHODS = ["card", "transfer"] as const
export type TPaymentMethod = (typeof PAYMENT_METHODS)[number]

export const isPaymentMethod = (value: unknown): value is TPaymentMethod =>
  PAYMENT_METHODS.some((method) => method === value)

const rawMethod = searchParams.get("method")
const method = isPaymentMethod(rawMethod) ? rawMethod : undefined
```

## References

- [references/narrowing.md](references/narrowing.md): input arrives as `unknown`, a string from the URL or storage, or a library hands back a wide type; and before writing `as`, `!` or a `typeof` check.
- [references/unions.md](references/unions.md): modelling states, a fixed set of values, a `switch` over a union, or replacing an `enum`.
- [references/type-sources.md](references/type-sources.md): before writing an interface by hand, when a literal object needs checking, naming a type, and `import type`.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
