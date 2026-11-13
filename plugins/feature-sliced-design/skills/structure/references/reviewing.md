# Reviewing: structure

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

**Hook-enforced — never re-report:** top-level layer of a new file; filename
case; barrel import from `shared/ui`; a domain type, an as-const constant, a
zod schema, a hook, or an HTTP call defined in a UI file; an upward or
sideways import; an entity calling `useMutation`.

**Script-checkable (`review` runs `structure-check.sh <changed files>`):** a
module missing its barrel; a barrel re-exporting a file that does not exist;
a `use-*.ts` outside `hooks/`; a `.api.ts` without a sibling
`.queries.ts`/`.mutations.ts`.

**Judgement — the rubric:**
- local vs global: a wrapper promoted to `shared/ui/` while it still carries
  one feature's domain knowledge ([references/ui.md](ui.md) row
  test) — quote the row
- a page holding business logic or fetching directly
- a module whose anatomy differs from the layer's skeleton without a stated
  reason
- an entity importing another entity through a relative path the hook cannot
  see
