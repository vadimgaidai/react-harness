# Where does unknown input get its type, and what replaces `as`, `!` and a defensive `typeof`?

## Narrow at the boundary, once

Input from outside the program (a response, URL params, storage, `postMessage`, a library
returning a wide type) is parsed where it enters: a zod schema for structured data, a type
guard for a single value. Downstream code trusts the type and does not check again.

`as` is a claim the compiler cannot check; a guard is one it can. A cast outside the
boundary usually means a value was stored with a wider type than it has, which forces every
reader to cast; the fix is the narrower type at the source.

```ts
export const isPaymentMethod = (value: unknown): value is TPaymentMethod =>
  PAYMENT_METHODS.some((method) => method === value)
```

`PAYMENT_METHODS.includes(value)` does not compile on a `readonly` tuple when `value` is a
wider type; `some` with `===` does, and needs no cast.

## `unknown` at the edge, never `any`

`any` disables the compiler for everything it touches, not just the value it is assigned
to: it flows into return types, parameters and every expression built from it. `unknown`
forces a narrow before use.

## Don't re-check what the type already guarantees

- No runtime `typeof` for what the type already says.
- No `!`: a value that may be missing is narrowed; one that cannot be is typed as present.
- No `?? fallback` on a value a parsed or locally produced type says is present; on unparsed outside data the fallback stays until a schema makes it unreachable.

A check the type makes redundant tells the next reader the type is not trusted, and it hides
the place where the type is actually wrong.
