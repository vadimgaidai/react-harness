# Reviewing: structure

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

**Hook-enforced — never re-report:** top-level bucket of a new file; filename
case; barrel import from `components/ui`; a domain type, an as-const
constant, a zod schema, a hook, or an HTTP call defined in a UI file; a
feature or page with its own `api/` folder.

**Script-checkable (`review` runs `structure-check.sh <changed files>`):** a
module missing its barrel; a barrel re-exporting a file that does not exist;
a `use-*.ts` outside `hooks/`.

**Judgement — the rubric:**
- local vs global: a component or hook promoted to a global bucket while it
  reads a feature's types or copy ([references/placement.md](placement.md)
  row test) — quote the row
- a page holding business logic or fetching directly
- a domain area (its own data and actions, usually its own `src/api/<resource>/`) built inside a page's `components/` instead of `features/<name>/` — the ladder's question 3 ([references/page-vs-layout-vs-feature.md](page-vs-layout-vs-feature.md))
- a module whose anatomy differs from the layer's skeleton without a stated
  reason
