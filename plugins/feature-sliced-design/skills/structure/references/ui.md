# UI Component Placement

> Where UI code lives in an FSD project. The *how* of building components (extending primitives, compound pattern, tokens) is the `ui-conventions` skill from the react-harness plugin — this file only decides the folder.

## The primitives folder is `shared/ui/`

- shadcn installs into `@/shared/ui/` here, not the default `@/components/ui/` — `components.json` aliases point there.
- Files in `shared/ui/` are managed by the shadcn CLI: flat, one primitive per file, imported by direct path (`@/shared/ui/button`), never through a barrel.
- Never edit a `shared/ui/` file to serve one domain's need — wrap it in the owning module instead. A hand edit there is lost on the next `npx shadcn add`.

## Where a component goes

| What it is | Where it lives |
|---|---|
| A shadcn/base primitive | `shared/ui/[name].tsx` — CLI-managed, flat |
| A domain wrapper around a primitive (`SubmitButton`, `SearchInput`) | the owning module's `ui/` — `features/[feature]/ui/`, `entities/[entity]/ui/` |
| A form component | the owning feature's `ui/` — `features/[feature]/ui/[name]-form.tsx`, one form per file; its schema goes in the same module's `model/schemas.ts` |
| A composite reusable block, incl. compound components | `widgets/[widget]/ui/` |
| A route-level composition | `pages/[name]/[name]-page.tsx` — composes, holds no UI logic of its own |

- A wrapper used by exactly one feature belongs to that feature, even if it "looks generic". Move it to `shared/ui/` only when a second module actually needs it *and* it carries no domain knowledge.
- Compound components (`.Root` + sub-components) are widget-sized by definition — 2+ coupled sub-components is a composite block. They never live in `shared/ui/`, which stays flat.
- Status/variant lookup maps and other domain constants a component renders from live in the module's `model/`, not inline in `ui/*.tsx`.
