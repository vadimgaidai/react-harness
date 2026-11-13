# Reviewing: code-shape

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

Two kinds of finding. A **style violation** is reported with the rule and the line; that is
enough. An **engineering remark** carries the argument: what the construct fails to name,
own or simplify at this spot; the data that already determines the value; the work repeated
per element. "Longer" alone is not a finding.

Style violations, most frequent first. Each is reported with the rule and the line.

- A comment, JSDoc that restates the signature and banner lines included. Code carries none. Two marks are allowed: `// TODO:` for work decided to be done
  later, and `// !` for important logic a reader must not break or "clean up". A tool
  directive with its reason (`// eslint-disable-next-line …`, `// @ts-expect-error …`) is not
  a comment and is not reported.
- A nested ternary, or a ternary that runs one of two actions instead of choosing one of two
  values.
- A function of ours that takes a third positional parameter. A signature a library sets (a
  `reduce` callback, an event handler) is not reported.
- An `if` without braces: `if (x) return y` or `if (x) save()` on one line.
- A function with branches that misses one of these: a value written in every `return`, the
  return type written on the signature, the same type from every branch.
- A boolean parameter: `formatAmount(total, true)` says nothing at the call site.

Engineering remarks, each with its argument:

- a wrapper that only forwards, a re-export that only renames, a variable that only repeats
  the returned expression, a default branch for a state the input is guaranteed never to
  hold, a check the code after it already handles, with the guarantee or the input that
  shows it named
- a search over a second collection repeated per element, a value recomputed per iteration,
  an intermediate array nobody reads, with the repetition named and the replacement's
  equivalence checked (order, duplicates, missing values, side effects)
- depth past two levels where inverting a condition would flatten it
- a generic or type-named identifier
- a function that only forwards or exists to shorten its parent, with why the name adds
  nothing
- a magic number with a domain meaning, or a string literal read back across a boundary
  (URL, storage, header) with no name
- a setter that re-passes every field for a one-field change, with the call sites named
- a `parse*` / `get*` / `format*` whose body sorts, dedupes or caches beyond its name, with
  the caller that depends on it
- a named, non-trivial pure function at module scope in a hook file, with where the
  structure skill puts it

Never a finding by itself: a single caller, an intermediate variable, a long file, a
`try/catch`, an optional chain, a fallback, a loop. Each needs the argument above.
