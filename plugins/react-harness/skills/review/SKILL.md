---
name: review
description: Checks a change against the project's and this harness's code rules, for unnecessary complexity and for inefficient data handling — reading only the context each question needs, and proving every finding before reporting it. Writes the report to `.planning/[name]/REVIEW.md` when the work has a planning folder. Reports only; fixes are a separate request through `refine`. Takes an optional angle argument (`skills`, `structure`, `sibling`, `slop`) and a git range or paths. Use before opening a PR, or when the user asks to review changes.
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/reviewing-sections.mjs)
argument-hint: "[angles] [range or paths] [.planning/<name>]"
context: fork
---

# Review

You check **the change under review**: does it follow our rules, is it more complex than
the task needs, does it handle data inefficiently. You read what a question needs and no
more, and you prove each claim. The project's typecheck, lint and tests stay the project's
checks. Not this skill's job: whether the change satisfies the spec and the contract
(`/react-harness:verify`), correctness bugs (`/code-review`), security
(`/security-review`), generic simplification (`/simplify`) — the report says so, and the
verdict never speaks for them.

## 1 — Define the scope

Say what is under review before reading a line, in this order of precedence:

1. **The user named a range or files** — that, exactly.
2. **A branch** — everything since `git merge-base HEAD <base>`, with `<base>` the one the
   user named, else `origin/HEAD`, else `main`.
3. **The current working state** — the branch's commits plus staged, unstaged and
   untracked work.

```bash
base=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD main)
git diff --stat "$base"; git diff --name-status "$base"   # branch + working tree vs base
git ls-files --others --exclude-standard                  # untracked files, part of the change
git diff --stat A..B; git diff --name-status A..B         # a commit range the user named
```

For a commit range, the code reviewed is the range's: `git diff A..B -- <file>` and
`git show B:<file>` for context, never the working tree's newer copy of the same file.
Plain git computes the scope; there is no wrapper for it. The report's header states the
scope used.

Added and removed lines are both the change. A finding is about a problem the change
introduced or made worse — a dropped guard and a deleted export get a verdict like an added
line. A defect that was already there in neighbouring code is not a finding.

Arguments: $ARGUMENTS

Argument: `review [angles] [range|paths] [.planning/<name>]`. Angles are `skills`, `structure`, `sibling`,
`slop`; none means all four. A focused run is a shorter report, never a narrower scope.

You are done when the report is in your reply and, when the arguments name `.planning/<name>`
or a `.planning/<name>/` folder exists for this work, in `.planning/<name>/REVIEW.md` too
(step 5). That file is your output, not an edit: "edits nothing" in step 6 means the code.

## 2 — Find the rules that apply

Only rules the project or this harness **states**; never an architecture inferred from folder
names, and never a plugin's presence as the precondition for a rule written down.

- `CLAUDE.md`, and every `.claude/rules/*.md` whose frontmatter `paths:` matches a changed
  file (or that has no `paths:`).
- A structure skill loaded in this session (`feature-sliced-design`, `feature-folders`, the
  project's own): its `references/reviewing.md`, and the check script it names
  (`structure-check.sh <changed files>`), whose lines go under **Checks**. No stated
  structure rules → the `structure` angle says so and makes no placement finding.
- The convention skill a hunk's content puts it under: an effect, state, memo, context or
  JSX → `react` (and `ui-conventions` for `className`); a query key, `useQuery`, mutation or
  invalidation → `tanstack-query`; a schema or form → `react-hook-form-zod`; a route, loader,
  search param or navigation hook → `routing`; a test file → `react-testing`; `try`/`catch`,
  `onError`, a toast, `??`/`?.` on data → `error-handling`; a type, cast, narrowing or
  `switch` on a union → `typescript`; branching, a helper, a loop over a collection →
  `code-shape`. Content decides, not the folder or the file name: a `use-*-filters.ts` in
  `hooks/` whose values come from `useSearchParams` is `routing` (and `code-shape` for its
  helpers). That skill's review questions (its `references/reviewing.md`) are already in this prompt, under
  [Review questions by skill](#review-questions-by-skill) at the end; do not call the skill
  for it. Open a reference file only for the one shape a finding needs to cite.
- The project's checks, as `package.json` defines them: typecheck, lint, tests. Run them
  without installing anything; record pass / fail and the output tail under **Checks**.
  A failing check is a finding and sets the verdict; it does not stop the review.

A hook or lint rule being configured is not proof it ran. Drop a candidate as a duplicate
only with an actual diagnostic of the same problem in hand — a line of this session's lint
output, a hook refusal in the trace — and cite it.

## 3 — Read file by file, ask everything of each

Start from the `--stat` and `--name-status` output. Then take one changed file, or a small
group that belongs together (a module's types, queries and component), and:

1. Read its diff with small context (`git diff -U3 "$base" -- <file>`; an untracked file is
   read whole if short, in ranges if not).
2. Ask every question below of what you just read — all four angles — before the next file.
   The diff is read once; it is never re-read per angle.
3. Expand only for a specific question: the condition above a hunk, the type of a value, the
   implementation of a helper the hunk calls, a caller of a new export. Find the symbol with
   `rg -n` and open the found range with a `limit`/`offset` read. Say in the finding what you
   opened and why.

Never load a whole large file, a neighbouring module, the entire PLAN or SPEC, or every
reference file as a matter of course. A large file changed throughout is read in parts; a
part you did not check is named in the report with the reason, never trimmed silently. The
number of reads is not the measure — purpose is.

**The comparison module** (the one `.planning/<name>/PLAN.md` names, or the obvious
neighbour — same layer, same role) is opened only when a specific decision benefits from the
comparison: how the sibling fetches, shapes an error, exports, names the same role. Read
the part that answers that — a ranged read of the original is fine;
`bash "${CLAUDE_PLUGIN_ROOT}"/skills/implement/scripts/sibling-outline.sh <path>` is a
convenience when you need the shape of the whole module, not a required step. Say which
module and why; none fits → the `sibling` angle says so.

## 4 — The questions

**`skills` — is this hunk an instance of a sentence in its governing skill's review questions
(below, under [Review questions by skill](#review-questions-by-skill))?**
A candidate quotes the sentence and the line. No sentence applies → no finding; there is no
spirit of the skill. A hunk that has a rubric's shape but meets the exception the same skill
states — a draft reset by `key`, a nested loop that must visit every pair, a sort on a local
copy, a `reset` on an entity change — is named as acceptable with that reason, never reported. The applicable `CLAUDE.md` / rules files are read the same way.

**`structure` — is this where the stated rules put it?** Only against rules found in
step 2: is this local thing promoted while only one module reads it, is this page holding
logic, does this import go against the declared direction. Quote the row or sentence.

**`sibling` — does this solve the same problem differently from the module it should
resemble?** A candidate is a structural mismatch you cannot account for — data layer,
error shape, exports, naming of the same roles — with the sibling's line beside the hunk's.

**`slop` — was this decision necessary?** Each names a cost; the candidate says what the
cost is *here* and what you checked to know.

1. **Unneeded generality** — an option, factory, generic or configuration nobody varies.
   Check the callers before saying "nobody".
2. **Repeat of an existing solution** — grep for the verb or the noun; name what you found,
   or that you found nothing.
3. **Redundant state** — a stored value that data already in scope determines; name the data.
4. **Empty layer** — a function or hook that renames, forwards or wraps one expression and
   owns no state and no boundary. Say what it fails to name or own.
5. **Unjustified defence** — a `try`/`catch`, fallback, `??` or default branch for a state
   that cannot occur. A TypeScript type is not a runtime guarantee for external data: find
   where the value is validated or produced and name it; no guarantee found → at most an
   open question.
6. **Project mismatch** — a second way to organise a query, a form, a component for an
   ordinary task. Look for the reason (a plan line, a difference in the data); only a found
   absence confirms.
7. **Repeated work over collections** — a search over one collection repeated for each
   element of another, a value recomputed per iteration, an intermediate array nobody
   reads. Name the repetition (`code-shape` §Collections by meaning). A loop is not a finding; a
   nested traversal that the task needs is not a finding; `map` with `find` inside or an
   inner loop moved into a helper does not remove the repetition.

Two kinds of finding, kept apart in the report:

- **Style violation** — a nested ternary, a comment that is not `TODO:` / `!` / a
  directive, a third positional parameter in our own function, a one-line `return`, a
  braceless `if`. The rule and the line are enough.
- **Engineering remark** — an unneeded helper, a redundant state, a repeated scan, a wrong
  owner for an error. It carries the argument: what the construct fails to name, own or
  simplify; the data that already determines the value; the work repeated per element.

Never a finding by itself: a single caller, an intermediate variable, a long file, a
`try/catch`, an optional chain, a fallback. Each needs the argument above or it is not
reported.

Both kinds name the rule they cite: a skill section (`code-shape §Boolean parameters`,
`routing/references/search-params.md §A hook that merges, never replaces`), a `CLAUDE.md`
or rules-file line, or one of the seven questions above.

## 5 — Check before you report

Each candidate passes five questions or it is dropped, or moved to open questions with
what would settle it:

1. Is it about the change — introduced or made worse by these lines?
2. Does the quoted rule apply to this line as written?
3. Is there a concrete complexity, repeated work or style violation, not a pattern match?
4. Is there context that justifies it — a plan line, a validation site, an external
   signature you cannot change, a mandatory callback shape?
5. Does the proposed change keep behaviour — same values for the same inputs, same order,
   same handling of duplicates and missing values, same side effects?

"Found a `useEffect` — slop" fails 3. "`fullName` is fully determined by `firstName` and
`lastName` (`CommentPanel` props, both required); storing it adds a sync and a second
render; derive it during render — the rendered text stays identical" passes all five.

Layout:

- **Header** — the scope as defined in step 1, `+added / −removed`, files not fully
  checked and why.
- **Checks** — each project check with pass / fail and its output tail as run in this
  session; a claim with no command output behind it is not made. The structure check's
  lines, when one ran. What was not run, and why.
- **Findings** — `file:line` → problem → the rule, cited by skill and section, with the
  concrete consequence for an engineering remark → proposed change. Style violations
  first, then engineering remarks, grouped by angle. Every confirmed finding is listed;
  none is cut for a cap, and none is added for count.
- **Open questions** — candidates with a real mechanism and an unverified fact, each with
  what would settle it. Apart from findings, never mixed in.
- **Verdict** — one line, for this review's scope only: *no findings against the checked
  rules* / *findings to take to `refine`* / *a project check is red*. Never "ready to
  merge": correctness and security were not reviewed here.
- **Not this skill's job** — one line: `/react-harness:verify` for the acceptance
  criteria and the contract, `/code-review`, `/security-review`, `/simplify`.

Write the same report to `.planning/<name>/REVIEW.md` when the arguments name that folder
or a `.planning/<name>/` folder exists for this work; a reply alone is not done. Frontmatter `status:` is `ready` only when every project check was
run and passed; `checks-failed` when one is red; `checks-skipped` when one could not run,
with the reason. Findings are `- [ ]` items with their four parts and a fenced `code`
block where the fix is exact enough to paste; open questions sit under `## Open questions`
as plain bullets — `refine` treats the first as work and the second as questions to
settle, never as tasks.

## 6 — Fixing is a separate request

`review` edits nothing — not even an obvious one-liner; a reviewer that edits is a second
implementer. When the user asks for the fixes, that is `/react-harness:refine`:
it reads `REVIEW.md`, verifies each item against the code as it is now, applies the fix
one item at a time with the typecheck after each, and declines with evidence what would
break behaviour or contradict the plan.

## Review questions by skill

Each convention skill's `references/reviewing.md`, read from the skill when this review
started. These are the sentences the `skills` angle quotes; a file reported as not found
means that skill states no review questions, and no `skills` finding cites it.

!`${CLAUDE_SKILL_DIR}/scripts/reviewing-sections.mjs`

## Last step

With a `.planning/<name>/` folder for this work, write `.planning/<name>/REVIEW.md` (step 5's
layout and `status:`) before you reply; then reply with the report.
