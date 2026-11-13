---
name: autopilot
description: One command for a small change to code that already exists — a field, a filter, a state, a tweak to behaviour the user can say in a sentence. Asks at most two questions, writes a short `.planning/[name]/SPEC.md` and `PLAN.md` in the same formats as `spec` and `plan`, then builds it through `implement`, and checks it with `verify` and `review`, each in its own forked context that never saw the build — one run, without stopping. Use when the user asks for a quick or small change; a new feature, a new screen or anything from a design goes to `/react-feature-workflow:spec`.
argument-hint: "[request]"
disable-model-invocation: true
---

# Autopilot

Request: $ARGUMENTS

You are done when step 0 sent the request to `/react-feature-workflow:spec`, or when `LOOP.md` is `finished`, `capped`, `stuck` or `stopped` and the step 6 report is written.

- One run: questions, `SPEC.md`, `PLAN.md`, `implement`, `verify`, `review`, report. You stop only when the request is too big for this command, a question blocks the build, or a stage refuses to hand off.
- The files use the headings of `spec` and `plan`, so `implement`, `verify` and `refine` read them unchanged. `SPEC.md` holds behaviour only: no paths, no function, component, hook or library names, no calls or signatures in a criterion; the verbatim request is the one exception.
- Never ask what the code answers; a lookup replaces the question.
- The code is written by `implement`, which loads the convention skills before the first edit. You write no code here.

## 0 — Size

Stop and say "this needs `/react-feature-workflow:spec`" when any of these hold:

- more than five acceptance criteria are needed;
- a new screen, route or module, not a change to one that exists;
- a Figma design to build from;
- a new dependency.

Where the line falls, by request:

```
stays  show the reply count next to each comment in the list — one detail on a list that exists
stays  add a sort by date to the comment list, kept in the URL — fits five criteria
spec   the sort above plus saved sort presets and a filter per author — more than five criteria
spec   add a page that exports the comments as CSV — new screen
spec   redo the comment list from this Figma frame — a design to build from
```

## 1 — At most two questions

Only behaviour that changes what the user sees and that the code cannot settle, through `AskUserQuestion`, one per turn, the recommended answer first. Everything else is a line under `## Assumptions`.

## 2 — `.planning/[name]/SPEC.md`

```markdown
# SPEC: [name]

**Shape:** change

## Request

The request, verbatim.

## Goal

One sentence, user-visible outcome.

## Behaviour

R-1 WHEN <event> THE UI SHALL <result>

## Unchanged behaviour

What must keep working exactly as before.

## Data sources

METHOD /path per endpoint, or "none".

## Acceptance criteria

AC-1 <checkable statement> (R-1)

## Assumptions

## Open questions
```

Two to five criteria, each citing an R-id, every R-id cited by one. Check ids and coverage before going on.

## 3 — `.planning/[name]/PLAN.md`

```markdown
# PLAN: [name]

**Spec:** `.planning/[name]/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules

| # | Path | Role | Depends on | Serves |

## Conventions to follow

The existing module this change lives in, or the sibling it mirrors.

## Contract

`.planning/[name]/contract.md`, or "none".

## Per module

### `path/to/module`

- **Files**: created or edited
- Only the lines that apply: **Types**, **Data layer** (and what each mutation invalidates), **Schemas**, **UI**

## Decisions

## Coverage

| AC | Modules | Evidence `verify` should expect |
```

An endpoint in Data sources is sliced the way `plan` does it, never read raw:

```bash
node "${CLAUDE_PLUGIN_ROOT}"/skills/api-contract/scripts/contract-slice.mjs \
  <url-or-path> .planning/[name]/contract.md "PATCH /comments/{id}"
```

Every AC maps to a module and every module serves an AC; a gap or an open question that changes the build stops the run with the item named.

## 4 — Build

Write `.planning/[name]/LOOP.md`, which the plugin's hooks read and keep to run the loop:

```markdown
---
status: running
iteration: 0
max_iterations: 4
---

# Loop: [name]
```

Invoke `react-feature-workflow:implement` with `[name]` and follow it to its typecheck, in this session. A typecheck left red stops the run with the output; one that cannot run (dependencies not installed) does not: note why and go on to step 5, where `verify` records it as `checks-skipped`.

## 5 — Verify, refine, review

The plugin's hooks run this loop from the files: only the next stage runs and any other is refused with the one to run, each `verify` counts a round, a `verify` or `refine` past `max_iterations` is refused, the same criteria failing two rounds in a row ends the loop as `stuck`, a code edit after a `verify` asks for a new one, and the turn does not end while a stage is left. Every call is logged in `LOOP.md`.

1. Invoke `react-feature-workflow:verify` with `[name]` and the scope; it forks its own context, pass it nothing about the build.
2. `VERIFY.md` `failed`: invoke `react-feature-workflow:refine` on its open items in this session, then `verify` again.
3. `ready` or `checks-skipped`: invoke `react-feature-workflow:review` with the same scope and `.planning/[name]`; it forks too.

A hook's reason names the next stage; do that. A call refused for the cap, or a `stuck` notice, ends the loop: go to the report. To stop for the user (a refine item you cannot settle, a red check), change `status: running` to `status: stopped` in `LOOP.md` and add the reason below the log; the hook refuses any other edit of that file.

## 6 — Report

When the turn ends with the loop `finished`, `capped`, `stuck` or `stopped`:

- files created and edited;
- criteria: how many `pass`, how many `unverifiable` with a pointer to the manual steps in `VERIFY.md`, each one still failing by id;
- review: the verdict line, the counts, the path to `REVIEW.md`;
- the rounds from `LOOP.md`, and every deviation a stage reported.

When the loop is `finished` and `REVIEW.md` has open `- [ ]` findings, end with: "Say `refine` to apply the review findings." On that reply, set `status: running` in `LOOP.md`, invoke `react-feature-workflow:refine`, and end your turn; the hook adds one round for it and sends you to `verify` again.
