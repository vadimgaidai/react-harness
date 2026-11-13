---
name: structure
description: Architecture-agnostic structure rules — global buckets, feature/page/layout module anatomy, the global-vs-local placement table, and a deterministic scaffolder. Use when creating a component, hook, provider, function or module, or deciding whether something is local to a module or belongs in a global bucket.
---

# Feature Folders

No layer hierarchy, no import-direction rule to enforce — this is the shape
for a project that isn't Feature-Sliced Design but still wants "where does
this go?" answered by a table instead of a guess. It works alongside decades
of existing code: the hook only ever blocks a **new** file in an unrecognized
place, never an edit to something already there. If the project actually
follows FSD's layered import direction, use the `feature-sliced-design`
plugin instead — don't install both in the same project.

## Top-level buckets

```
src/
├── app/          entry point, router, root providers
├── pages/        route-level modules — one per route
├── layouts/      route shells: persistent chrome + the providers it mounts
├── features/     a user-facing capability with its own state — not tied to one page
├── components/   global, domain-free components; components/ui/ is CLI-managed and flat
├── hooks/        global, domain-free hooks
├── providers/    global context providers, mounted in app/ or a layout
├── lib/          pure functions and infrastructure (http client, query client, storage)
├── config/       env, route paths, app-wide constants
├── api/          HTTP calls + query/mutation hooks, one folder per backend resource
└── assets/       static files, global styles
```

Every bucket's name is enforced at write time for **new** files by this
plugin's bucket-placement check — editing an existing file never
trips it, so a legacy tree with its own conventions in half of `src/` is left
alone; only new work is steered into these buckets. A file sitting directly in
`src/` (`main.tsx`, `App.tsx`, `vite-env.d.ts`) is in no bucket and is left
alone too.

## Three questions decide everything

1. **Is this a page, a layout, or a feature?** → the three-question ladder in
   [references/page-vs-layout-vs-feature.md](references/page-vs-layout-vs-feature.md).
2. **Is this piece of it local to that module, or does it belong in a global
   bucket?** → the table in [references/placement.md](references/placement.md)
   — one row per role (component, hook, provider, type, constant, function),
   each with a mechanical test, default always local.
3. **Does this call an API?** → always `src/api/<resource>/`, from the first
   call, keyed by backend resource, never by feature. See
   [references/api.md](references/api.md).

If a thing doesn't fit any bucket after the ladder and the table, it is
usually two things — split it before placing it.

## Reading the reference files

Every reference file uses placeholders (`[name]` kebab-case, `[Name]`
PascalCase) — substitute your own names. Open only the one that matches what
you're about to write:

| Writing | Read |
|---|---|
| a new page, layout, or feature — which one, and its skeleton | [references/page-vs-layout-vs-feature.md](references/page-vs-layout-vs-feature.md) |
| deciding local vs. global for a component/hook/type/constant/function | [references/placement.md](references/placement.md) |
| any HTTP call, query or mutation | [references/api.md](references/api.md) |
| a context/provider | [references/providers.md](references/providers.md) |
| a component — which folder, compound vs. wrapper vs. primitive | [references/components.md](references/components.md) |
| a public barrel | [references/barrels.md](references/barrels.md) |

[references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.

## Naming

Files and folders are `kebab-case`. Pages are `[name]-page.tsx`, layouts are
`[name]-layout.tsx`. Enforced by the kebab-case check.

## Where rendered output lives

Rendered output lives under four folder names and nowhere else: `ui/`, `components/`,
`pages/` and `layouts/` — at the top level (`src/components/`, `src/pages/`,
`src/layouts/`) and inside a module alike (`features/[name]/components/`,
`components/ui/` for primitives). The content rules are enforced exactly there: a `.tsx`
under one of those four may not define a domain type, an as-const constant, a zod schema,
a hook or an HTTP call. A `.tsx` anywhere else is outside the standard — the content rules
cannot see it, so it is a placement question for `review` rather than a refused write.

## Scaffolding

Deterministic, not model-generated:

```bash
bash "${CLAUDE_PLUGIN_ROOT}"/skills/structure/scripts/scaffold.sh <bucket>/<name> [relative-file ...]
```

`<bucket>` is `features`, `pages`, `layouts`, or `api` — the ones with a fixed
module anatomy. Omit the file list for the bucket's default skeleton. The
script validates kebab-case and refuses to touch an existing module — if it
refuses, the module exists: extend it instead. The single-file global buckets
(`components/`, `hooks/`, `providers/`, `lib/`, `config/`, `assets/`) aren't
scaffolded — there's no skeleton, just one file, added with Write.
