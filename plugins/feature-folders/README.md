# Feature Folders

Structure for React projects that are not Feature-Sliced Design: global buckets (`components/`, `hooks/`, `providers/`, `lib/`, `config/`, `api/`, `assets/`), `app/` for the entry point and root providers, plus `features/`, `pages/` and `layouts/` modules. A skill answers "local or global?"; one hook refuses a new file that lands outside them.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install feature-folders@vadimgaidai --scope project
```

Needs `node` — the hook is a Node script, and without it nothing is checked and nothing is blocked. Keep `--scope project`. Do not install together with `feature-sliced-design`.

## What the hook refuses

- a **new** file outside `app/`, `pages/`, `layouts/`, `features/`, `components/`, `hooks/`, `providers/`, `lib/`, `config/`, `api/`, `assets/` — a file sitting directly in `src/` (`main.tsx`, `App.tsx`, `vite-env.d.ts`) is in no bucket and passes. `src/utils/format.ts` is pointed to `src/lib/`, `src/services/comments.ts` to `src/api/comments/`
- a filename under `src/` that is not kebab-case
- an import through the `@/components/ui` barrel instead of `@/components/ui/button`
- a domain type, an `as const` constant, a zod schema, a hook or an HTTP call written into a `.tsx` under `ui/`, `components/`, `pages/` or `layouts/` — the four folders rendered output lives in; a feature or page with its own `api/` folder

Placement and naming check new files only. Editing a file that existed before the plugin always passes, so a project with years of structure is not fought. The content and barrel rules check old files too: a domain type pasted into an old component, or a barrel import added to one, is still new.

## What the skill answers

Whether something is a page, a layout or a feature, in three checks. Whether a component, hook, provider, type, constant, function, schema or API call is local to a module or global, by a table with one condition per role. Where an API call lives (`src/api/<resource>/`, never inside a module). Reference code for each kind of module.

`scaffold.sh` creates a feature, page, layout or api module skeleton and refuses to touch an existing one. `structure-check.sh` finds a module without a barrel, a barrel re-exporting a missing file, a `use-*.ts` outside `hooks/`; `react-feature-workflow`'s `review` runs it over changed files.

Works alone or with [react-feature-workflow](../react-feature-workflow). MIT.
