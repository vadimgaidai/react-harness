# Reviewing: typescript

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- `as` outside a boundary
- `any` / `!` / `@ts-ignore`
- an optional-everything interface where a union was meant
- a duplicated inferred type
- an `interface` without the `I` prefix, a union or derived `type` without the `T` prefix, or
  an object shape written as a `type`
- a `typeof` guard on a value the type already narrows
- a non-exhaustive `switch` on a union
- an inline string-literal union for a prop or a key whose set should be a const-derived union
- a type that lets an invalid state be built — two booleans where a union of states was
  meant, an optional field that is required in every real case, a string where the set of
  values is known
- an invariant held only in a comment or a runtime check, when the type could carry it
