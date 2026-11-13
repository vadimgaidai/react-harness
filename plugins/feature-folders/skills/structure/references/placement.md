# Global or local — one table, no judgment call

> This file exists because "global or local" is the question that otherwise gets
> guessed differently every time. Each row has a mechanical test. If none of them
> fire, the default wins — local, inside the module that needs it.

**Default: local.** Everything below starts in the module (`features/<name>/`,
`pages/<name>/`, `layouts/<name>/`) that first needed it. It is promoted to a
global bucket only when its row's condition is true — never preemptively,
never "because it might be reused".

| Role | Local default | Promote to global when… | Global home |
|---|---|---|---|
| Component | `<module>/components/` | it renders nothing domain-specific (no feature's types, no feature's copy): global from the start, like a chart blank or a stat tile; or it is imported by a **second** module once its domain part is split off | `src/components/` |
| Hook | `<module>/hooks/` | same test as component: a second module needs it and it holds no domain knowledge | `src/hooks/` |
| Provider / context | `<module>/providers/` | it is mounted in `src/app/` or in a layout, so more than one page sees it | `src/providers/` |
| Request/response type | in the request's module | the shape is named in `contract.md`, or a second module calls the same endpoint | `src/api/<resource>/types.ts` |
| Domain type (not from an API) | `<module>/types.ts` | a second module needs the same shape | promote to whichever module both share, or `src/api/<resource>/types.ts` if it is the resource's shape |
| Constant / enum-like `as const` | `<module>/constants.ts` | read by two modules, or it configures the app itself (a route path, a feature flag) | `src/config/` |
| Function | `<module>/` (inline or a local helper file) | it is pure (no domain types, no module state) **and** a second module needs it | `src/lib/` |
| Validation schema (zod) | `<module>/schemas.ts`, next to the form it validates | a second module needs the exact same schema | promote to whichever module both share |
| HTTP call / query / mutation | never local — see below | — | `src/api/<resource>/` always, from the first call |

## The one role that is never local: API

Every HTTP call lives in `src/api/<resource>/`, keyed by the **backend resource**
(`articles`, `users`, `auth`), not by the feature that happens to call it first.
This isn't a promotion rule — it's the rule from the start, because `contract.md`
is sliced per resource and two features calling the same endpoint must share one
client function, one query key, one cache entry. A feature's `hooks/use-<name>.ts`
composes calls from `api/<resource>/` with local state; it does not own an
`api/` folder of its own. See [references/api.md](api.md).

## The real test is what it renders, not who calls it

A component or hook that is reused but still prints one feature's copy, reads
one feature's types, or reaches into one feature's state is not generic — it is
that feature's code living in the wrong folder, and the next person to read it
in `src/components/` will assume it's safe to change for anyone. Promote the
*shape*, not the instance: extract the domain-free part (an accordion row, a
`use-debounced-value` hook) and leave the domain-specific part (what the row
renders, what value it debounces) where it started.

## Worked examples

- A `<SettingsRow icon={...} text={...} onClick={...}>` used only by the settings
  page stays in `pages/settings/components/`. The day a second page needs a row
  with the same shape, it moves to `src/components/` unchanged — the props
  already carried no domain knowledge.
- A `use-auth-state` hook reads tokens and the current user — domain-specific —
  and stays in `features/auth/hooks/`, never promoted, however many places call
  `useAuth()` from the feature's barrel.
- A `use-debounced-value(value, delay)` hook has no domain in it from day one.
  It can start directly in `src/hooks/` even before a second caller exists,
  because the test ("holds no domain knowledge") is already true — promotion
  timing is about domain-freeness, not usage count alone.
- `paths.settingsPage` is a route string. It is app-wide configuration by
  definition, so it lives in `src/config/` from the start, never in a feature.
