---
name: code-shape
description: House rules for the shape of every .ts/.tsx file — comments, function parameters, options objects, if/return blocks, guard clauses, ternaries, loops over arrays (map, filter, find, reduce), helpers and utils, setters, constants, naming. Use whenever writing, editing or reviewing TypeScript or TSX, a function, a hook's helper or a utility, even for a small change.
---

# Code shape

- The least code that does the job: no wrapper that only forwards, re-export that only renames, variable that only repeats the returned expression, default branch for a state the input cannot hold, check the code after it already handles, or parameter nothing passes yet.
- No comments. Two marks only: `// TODO:` for work decided to be done later, `// !` for important logic a reader must not break. JSDoc that restates the signature, banners and "for now" notes are comments too. A tool directive with its reason (`eslint-disable`, `@ts-expect-error`) is not a comment.
- Two parameters at most in a function of ours: the first stays positional, the rest go into one typed options object, so the call site names every value and their order stops mattering. A callback whose signature a library sets (`map`, `reduce`, an event handler) keeps it.
- Guard clauses first: exit cases return at the top, the happy path stays unindented.
- A `return` sits in a braced block, never `if (x) return y` on one line, so every exit is visible when scanning the left edge; same for any single-statement `if`.
- A ternary chooses between values, never between behaviours, and never nests, because a nested one hides which condition wins.
- Collections by meaning: `map`/`filter`/`find`/`some`/`every` where they say the operation; no search repeated per element, value recomputed per iteration or intermediate array nobody reads.
- A branching body writes the value in every `return` and annotates the return type, so a new branch cannot widen the type unnoticed; implicit arrow returns are for one expression. A component's JSX return is inferred.
- No boolean parameters, since `formatAmount(total, true)` says nothing at the call site: split the function, or fold the flag into the options object.
- A setter for a group of fields takes a patch (`Partial<State>`), never the whole state re-passed with one field changed: a call that forgets the spread silently resets the other fields.
- A literal another side reads back (search param, storage key, header) and a number with a domain meaning get a named constant, so the two sides agree through one name.
- A `parse*`/`get*`/`format*` does that one thing, or its name says what else it does.
- A pure, named, multi-expression helper in a hook file moves where the structure skill puts a module's pure functions.
- Every user-facing string (a toast, a label, a schema message, a fallback like `"Untitled"`) goes through `t("key")`, in a `.ts` file as much as in a component; `ui-conventions` owns the detail.
- Names say the domain, not the type: no `data`, `flag`, `handleClick` (a handler is named by what it does: `submit[Entity]`, `openFilters`), no `Helper`/`Manager`/`Utils`/`Service` or `2` suffix; grep before naming.
- Extract a function for a name or a responsibility, not for size; one that only forwards is inlined.

## Example

A third parameter goes into an options object; the `reduce` callback keeps its three because the library sets that signature.

```ts
const formatAmount = (value: number, decimals: number, currency: string) => …
formatAmount(total, 2, currency)
```

```ts
interface IFormatAmountOptions {
  decimals: number
  currency: string
}

const formatAmount = (value: number, { decimals, currency }: IFormatAmountOptions) => …
formatAmount(total, { decimals: 2, currency })

const weighted = prices.reduce((sum, price, index) => sum + price * weights[index], 0)
```

## References

- [references/shapes.md](references/shapes.md): when a rule's edge is in doubt (when a variable, wrapper or `default` branch stays; when a `Map` may replace a `find`; what a block `return`, a setter patch, a boundary constant or a moved hook helper looks like), or when a finding needs the shape to cite. Each rule has a section under its own name, cited as `code-shape §<section>`.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
