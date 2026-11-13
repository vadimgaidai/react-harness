---
name: structure
description: Feature-Sliced Design rules — layers, import direction, module anatomy, the model split, and a deterministic module scaffolder. Use when creating a module, deciding which layer code belongs to, or resolving an import-boundary question.
---

# Feature-Sliced Design

For a Vite + React Router SPA: standard `pages` layer, **not** the `views` layer some generic guides use.

## Layers

```
app → pages → widgets → features → entities → shared
```

- Import **downward only**. Never upward, never sideways within a layer — a feature must not import another feature, an entity must not import another entity.
- Cross-layer imports go through `@/`; relative imports only within one module. External code enters a module only through its `index.ts` barrel. The one exception is UI primitives (`@/shared/ui/[name]`), imported by direct path so the bundle doesn't pull the whole barrel.

The import direction and the naming rules below are enforced by this plugin's PreToolUse hook — a violating write is blocked, so don't spend effort re-checking them by hand. A file sitting directly in `src/` (`main.tsx`, `vite-env.d.ts`) belongs to no layer and is left alone.

## Which layer?

- **entity** — a domain resource, read side: `api/[name].api.ts` + `api/[name].queries.ts`, `model/`, `index.ts`. No mutations.
- **feature** — a user action, write side: `api/[name].api.ts` + `api/[name].mutations.ts`, `hooks/`, `model/`, optional `ui/`, `index.ts`.
- **widget** — a composite reusable block: `ui/`, optional `config/` and `model/`, `index.ts`.
- **page** — one route-level file, `[name]-page.tsx`. Composes widgets and features; holds no business logic.
- **shared** — infrastructure only: http client, query client, storage, config, UI primitives. Nothing domain-specific.

If a thing does not fit a layer, it is usually two things. Split it before placing it.

## Module anatomy

Every module has the same skeleton — see [references/fsd-module-anatomy.md](references/fsd-module-anatomy.md):

```
[module]/
├── api/         # HTTP calls + query/mutation hooks
├── hooks/       # use-*.ts composed from api/model
├── model/       # types.ts, constants.ts, schemas.ts — domain only
├── ui/          # components (optional)
└── index.ts     # public barrel — the only import surface
```

## The model split is literal

- A **value** goes in `constants.ts` — including the `as const` object that stands in for an enum.
- A **type** goes in `types.ts` — including the union derived from that object, imported type-only. That is not a circular dependency.
- Zod schemas go in `schemas.ts`, never inline in a component or in `api/`.
- Domain interfaces, status/variant lookup maps and magic constants live in `model/`, never inline in `ui/*.tsx`. A component's own one-off props interface may stay local.

## Naming

Files and folders are `kebab-case`. Suffixes: `.api.ts`, `.queries.ts`, `.mutations.ts`. Pages are `[name]-page.tsx`.

## Where rendered output lives

Rendered output lives in a slice's `ui/` and, for page files, in `pages/`
(`pages/[name]/[name]-page.tsx`) — the two the anatomy above produces. The content rules
are enforced there, and under `components/` and `layouts/` as well, for a project that
still carries those folder names from before the migration: a `.tsx` under any of the four
may not define a domain type, an as-const constant, a zod schema, a hook or an HTTP call.
A `.tsx` elsewhere in a slice — in its root, or under `model/` — is outside the anatomy,
so the content rules cannot see it and `review` takes it as a placement question.

## Scaffolding a module

Deterministic, not model-generated:

```bash
bash "${CLAUDE_PLUGIN_ROOT}"/skills/structure/scripts/scaffold.sh <layer>/<name> [relative-file ...]
```

Omit the file list for the layer's default skeleton. The script validates kebab-case and refuses to touch an existing module — if it refuses, the module exists: extend it instead.

## Reading the canonical code shapes

Every reference file uses abstract placeholders — never a real module, so nothing breaks when a template module is deleted. Substitute your own names:

| Placeholder | Stands for |
|---|---|
| `[entity]`, `[feature]`, `[widget]` | the kebab-case module name |
| `[Entity]` | its PascalCase form |
| `I[Entity]`, `T[Entity]Status` | its type identifiers |
| `[ENTITY]_ENTITY`, `[ENTITY]_QUERY_KEYS` | its constants |
| `[entity]Api`, `[entity]Keys`, `[entity]Queries` | its api surface |

**Real infrastructure keeps its real name.** `httpClient`, `createQueryKeyFactory`, `env` and the UI primitives under `@/shared/ui/` are the foundation layer — always present, never a placeholder. If a reference file names one of those, use it verbatim.

Open the **one** file that matches what you are writing, never the set:

| Writing | Read |
|---|---|
| an entity module | [references/entity.md](references/entity.md) |
| a feature module | [references/feature.md](references/feature.md) |
| queries | [references/queries.md](references/queries.md) |
| mutations | [references/mutations.md](references/mutations.md) |
| types, unions, `as const` sets | [references/typing.md](references/typing.md) |
| a public barrel | [references/barrels.md](references/barrels.md) |
| a UI component — which folder | [references/ui.md](references/ui.md) |

[references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
