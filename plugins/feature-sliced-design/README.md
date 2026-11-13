# Feature-Sliced Design

The structure plugin of [React Harness](../../README.md) for a [Feature-Sliced Design](https://feature-sliced.design/) project: a skill answers where code goes and in which direction it may import; one hook refuses the write when it goes elsewhere. Pair it with `react-harness` for the code rules inside the files.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-harness
claude plugin install feature-sliced-design@vadimgaidai --scope project
```

Needs `node` — the hook is a Node script, and without it nothing is checked and nothing is blocked. Keep `--scope project`: the hook assumes all of `src/` is FSD and would block writes in any other project. Do not install together with `feature-folders`.

## What the hook refuses

Every `Write` and `Edit`:

- a file outside `app/`, `pages/`, `widgets/`, `features/`, `entities/`, `shared/` — a file sitting directly in `src/` (`main.tsx`, `vite-env.d.ts`) is in no layer and passes
- a filename under `src/` that is not kebab-case (`UserCard.tsx`)
- an import through the `@/shared/ui` barrel instead of `@/shared/ui/button`
- an import against the layer order: an entity importing a feature, a feature importing another feature. The hook reads `@/`-aliased imports; the same violation written as a relative path escapes it and stays a `review` question
- a domain type, an `as const` constant, a zod schema, a hook or an HTTP call written into a `.tsx` under `ui/` or `pages/` — the two folders rendered output lives in, plus `components/` and `layouts/` where a project still has them
- `useMutation` inside an entity

The message names the correct place, so Claude fixes it in the same turn.

## What the skill answers

Layers and import direction, module anatomy, the model split (`types.ts`, `constants.ts`, `schemas.ts`), reference code for entities, features, queries, mutations, barrels, UI placement and typing. It loads on its own when Claude creates a module or resolves an import question.

Two scripts come with it. `scaffold.sh` creates a module skeleton on the right layer in one call and refuses to touch an existing module. `structure-check.sh` finds a module without a barrel, a barrel re-exporting a missing file, a `use-*.ts` outside `hooks/`; `react-harness`'s `review` runs it over changed files.

Works alone or with [react-harness](../react-harness). MIT.
