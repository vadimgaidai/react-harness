# Page, layout, or feature — a three-question ladder

> Replaces guessing with a test asked in order. Stop at the first "yes".

```
1. Does it wrap route(s) with persistent chrome (sidebar, header, tab bar)
   and mount providers shared by everything inside it?
     yes → layouts/<name>/
     no  → next question

2. Does it have its own entry in src/config's route paths?
     yes → pages/<name>/
     no  → next question

3. Is it a domain area of its own — data and actions the user knows by a name
   (comments, attachments, billing, notifications), usually backed by its own
   src/api/<resource>/?
     yes → features/<name>/, from the first iteration, even while one page
           is its only caller
     no  → it is a piece of one page's own layout (a header row, a section
           shell, a hero block) and stays in that page's components/;
           a piece with no domain at all is global, see references/placement.md
```

A page only composes: it reads its route params and places layouts and features. A domain
area does not wait for a second page to become a module, because work is built in parts and
the second caller usually arrives in a later iteration; moving a grown folder out of a page
then is a refactor nobody schedules.

## Worked examples

- A dashboard shell with a sidebar, mounted once in the router and wrapping
  every `/app/*` route: **layout** — `layouts/dashboard/dashboard-layout.tsx`.
- `/issues/:id`, reachable from the router: **page** — `pages/issue/issue-page.tsx`, which
  places the issue body, the comment thread and the attachments and activity tabs.
- The comment thread on that page: **feature** — `features/comments/`, with its composer,
  replies and pagination, even though the issue page is its only caller today. Attachments
  with their upload action are `features/attachments/`, the activity log `features/activity/`.
- The page's title row with the issue number and status: not a domain area of its own, it
  heads this page — `pages/issue/components/issue-header.tsx`.
- A bar chart that takes points, a config and formatters and knows nothing about issues: no
  domain at all — `src/components/bar-chart.tsx` from the start; the activity chart that
  feeds it lives in the feature that owns the data.

## Module anatomy — the same skeleton for all three

```
<name>/
├── components/   # local sub-components — not imported outside this module
├── hooks/        # use-*.ts composed from src/api/ + local state
├── providers/    # a context this module owns and mounts itself (rare)
├── types.ts      # domain types local to this module
├── constants.ts  # values and as-const sets local to this module
└── index.ts      # public barrel — the only import surface
```

A page additionally has `<name>-page.tsx` at its root; a layout has
`<name>-layout.tsx`. A feature has neither — it is composed by whatever page or
layout uses it, so its barrel is its only fixed file beyond the skeleton.

Omit a folder the module doesn't need — a feature with no sub-components has
no `components/` folder at all, and most modules never need `providers/`.

See [references/placement.md](placement.md) for whether a given
component, hook or type stays inside this skeleton or is global from the
start, and [references/barrels.md](barrels.md) for what the barrel
exports.
