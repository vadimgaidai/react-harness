---
name: verify
description: Checks each acceptance criterion in `.planning/[name]/SPEC.md` against the change and writes `VERIFY.md` with a verdict and the evidence per criterion. Reports only. Use after implement or refine, or when the user asks whether the work meets the spec.
argument-hint: "[name] [range or paths]"
context: fork
---

# Verify

You answer one question: does the change satisfy `SPEC.md`, criterion by criterion. You are
done when `.planning/[name]/VERIFY.md` exists, every `AC-` id in the spec has exactly one
verdict with evidence behind it, and the check script in step 6 passes.

You edit no code and write no tests: a verifier that writes the test it then passes is
grading its own work. Code quality is `review`'s question. You run in a forked context and
see nothing of the session that built the change, so everything you use comes from disk.

Arguments: $ARGUMENTS

## Inputs

- **Name** — the first argument. Without one, the only folder under `.planning/` that holds
  a `SPEC.md`; with several, stop and list them, because you cannot ask.
- `SPEC.md` — acceptance criteria, behaviour rules, UI states, permissions and, for a
  change, Unchanged behaviour. Missing means there is nothing to verify: say so and stop.
- `PLAN.md` — its Coverage table says which modules should prove which criterion. It tells
  you where to look first, not what to believe.
- `contract.md`, when present — the authority for every request and response shape.
- **The change** — the range or paths from the arguments. Without them, everything since
  the merge-base plus staged, unstaged and untracked work:

  ```bash
  base=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD main)
  git diff --stat "$base"; git ls-files --others --exclude-standard
  ```

## Steps

1. **Run what the project has.** Its test command when one exists (`package.json` scripts,
   a `vitest`, `jest` or `playwright` config), then the typecheck. Keep the last lines of
   each output; they are the only `executed` evidence you will have.
2. **Give every criterion one verdict and one tier**, in the spec's order. Read the hunks
   the Coverage table points at first and others only when those do not settle it.

   | Verdict | Tier | Evidence the line carries |
   |---|---|---|
   | `pass` | `executed` | the command in backticks and the output line that shows it |
   | `pass` | `static` | a `file:line` in the change and the reason that line suffices |
   | `fail` | `executed` or `static` | what is missing or wrong, and the `R-` rule it breaks |
   | `unverifiable` | `manual` | numbered steps a human performs, and what they should see |

3. **Contract.** Every type and payload the change introduces against `contract.md`:
   required versus optional, enums, nullability, formats. A field the contract does not
   list is a finding however plausible it looks, and so is a mutation that writes a
   client-assembled object into the cache where the server's response belongs.
4. **Coherence.** Whether `PLAN.md` still describes the code: modules at the paths in its
   table, each Decisions entry matching what was built, and for a change, no hunk touching
   what Unchanged behaviour protects unless the hunk is explained.
5. **What the spec does not say.** A behaviour a user would expect that the spec never
   names goes under Spec gaps, because the implementer followed the spec and the spec is
   what needs fixing. Code the spec does not cover at all goes under Declined to judge,
   named and not judged.
6. **Write the file, then check it.**

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}"/skills/verify/scripts/check-verify.mjs .planning/[name]
   ```

   Fix what it names and run it again until it prints `ok`.

## Three calls that are easy to get wrong

Static evidence is the line that implements the criterion, not the file that might.

```
no   - [x] AC-2 — static — comment-form.tsx exists and renders the form
yes  - [x] AC-2 — static — src/features/comments/ui/comment-form.tsx:41 — submit is disabled while isPending
```

A green suite is evidence only for the criteria its tests exercise.

```
no   - [x] AC-1 — executed — `pnpm test`: 48 passed
yes  - [x] AC-1 — executed — `pnpm test comments`: "renders oldest first" passed
```

A missing behaviour the spec never asked for is a gap in the spec, not a failed criterion.

```
no   - [ ] AC-1 — fail — static — the list has no empty state
yes  ## Spec gaps
     - the comment list has no empty state; no rule or criterion names one
```

## VERIFY.md

```markdown
---
stage: verify
status: failed
scope: working tree since a1b2c3d
pass: [AC-1, AC-2]
fail: [AC-3]
manual: [AC-4]
---

## Checks
`pnpm test` — 12 passed · `pnpm typecheck` — clean

## Criteria
- [x] AC-1 — executed — `pnpm test comments`: "renders oldest first" passed
- [x] AC-2 — static — src/features/comments/ui/comment-form.tsx:41 — submit is disabled while isPending
- [ ] AC-3 — fail — static — nothing handles 409; R-5 requires a conflict message
- [?] AC-4 — unverifiable — manual — 1. open /articles/1 offline 2. submit 3. expect the retry toast

## Contract
file:line — the claim — why it contradicts the contract. Or "none".

## Coherence

## Spec gaps

## Declined to judge
```

`status` is `failed` when any criterion fails, `checks-skipped` when a project check could
not run (say which and why under Checks), otherwise `ready`. Every `AC-` id from the spec
sits in exactly one of `pass`, `fail`, `manual`.

Reply with the status, the Criteria lines and the path, and nothing about the code beyond
them. Fails go to `/react-feature-workflow:refine`; a `ready` file goes to
`/react-feature-workflow:review`.
