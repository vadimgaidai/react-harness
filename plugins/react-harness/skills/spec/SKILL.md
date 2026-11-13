---
name: spec
description: Turns a request into `.planning/[name]/SPEC.md` — user-visible behaviour, UI states, permissions, failure scenarios and acceptance criteria with ids — before any module, file or library is named. Classifies the request as block / layout / feature / change, hunts the gaps the request left unsaid by taxonomy, asks at most five questions and records the rest as assumptions. Use when the user wants to plan, spec, scope or start a feature, module, change or refactor; the first command of the full workflow. A small change to existing code that should go straight to code is `autopilot`.
disable-model-invocation: true
---

# Spec

You write the WHAT. The human reads and corrects this file before any HOW exists, so it
holds behaviour, not implementation: no module paths, no component names, no library names,
no hooks, no code. `/react-harness:plan` turns it into modules afterwards.

**One request = one SPEC.md**, at `.planning/[name]/SPEC.md`, `[name]` kebab-case.

## 0 — Shape of the request

A `block:`, `layout:`, `feature:` or `change:` prefix means the user classified it
themselves: take that shape as given, and say in one line if it clearly mismatches before
following it anyway. Without a prefix, classify from the request.

| Shape | What it looks like | Spec |
|---|---|---|
| **block** | One presentational block — a hero, a pricing card, a header | None. Reply "run `@react-harness:block-builder <node-url> into <path>`" and stop. |
| **layout** | A page assembled from blocks — a landing, a marketing page | Light spec: name, one node URL per block, which composites repeat, text/i18n, 2–4 AC. Skip the taxonomy pass. |
| **feature** | Behaviour — data, forms, state: a table, a chat, a checkout | Full spec. |
| **change** | An edit to a module that already exists | Full spec in delta form: what is added, modified, removed, plus **Unchanged behaviour**. |

A block is a section or a self-contained composite, never an element. A request that mixes
shapes — a landing with a working contact form — is a **feature**.

## 1 — Hunt the gaps (feature and change)

Rate each category from the request plus point lookups in the codebase — `Glob`/`Grep` and a
ranged `Read`, never bulk reading — as **Clear**, **Partial** or **Missing**:

1. **Scope and goal** — what the user sees done
2. **Data and entities** — what is shown, which endpoints as `METHOD /path` (no shapes)
3. **UX flow** — screens, entry points, navigation, what happens after success
4. **UI states** — loading, empty, error, partial, disabled; per screen
5. **Permissions** — who sees what, who may do what; action-level, not only render-level
6. **Persistence** — URL state, local storage, what survives reload and back
7. **Failure scenarios** — network, 4xx/5xx, double submit, stale data, optimistic rollback
8. **Non-functional** — a11y, list sizes and pagination, i18n, responsive
9. **Done signals** — how the user will know it works; this seeds the acceptance criteria

For a **change**, add one: what must keep working exactly as it does today.

## 2 — Ask at most five questions

Rank the Partial and Missing categories by impact × uncertainty and ask the top five through
`AskUserQuestion`, one question per turn, never a batch.

- **Lead with a recommendation** — the first option is your recommended answer, labelled
  "(Recommended)", with a one-line rationale.
- **Never ask what the codebase answers.** A targeted lookup that settles the question
  replaces it.
- **Never ask HOW.** Shapes, modules, structure, dependencies and component names are
  `plan`'s questions, not yours. Design node URLs are input, so collect those here.

Everything still Partial or Missing after five questions becomes an **informed guess**,
written into `## Assumptions` as one line each. A guess recorded in the file is cheaper to
reverse than a sixth question.

## 3 — Write `.planning/[name]/SPEC.md`

```markdown
# SPEC: [name]
**Shape:** feature | layout | change

## Request
The user's original request, verbatim.

## Goal
One sentence, user-visible outcome.

## Behaviour
R-1 WHEN <event> THE UI SHALL <result>
R-2 WHILE <state> THE UI SHALL <result>
R-3 IF <failure> THEN THE UI SHALL <result>

## UI states
Per screen: loading / empty / error / partial.

## Permissions
Role → sees / may do. Or "none".

## Persistence
What lives in the URL, locally, on the server; what survives reload. Or "none".

## Failure scenarios
Each named, with the expected behaviour.

## Non-functional
a11y, list sizes, i18n namespace, responsive. Only what applies.

## Unchanged behaviour
(change shape only) What must keep working exactly as before.

## Data sources
METHOD /path per endpoint; the OpenAPI URL or path. Shapes are plan's job.

## Design
Figma node URL per block, or "none".

## Acceptance criteria
AC-1 <checkable statement> (R-1, R-3)
AC-2 <checkable statement> (R-2)

## Out of scope
Explicit non-goals.

## Assumptions
Guesses made instead of asking; each reversible by editing this file.

## Open questions
Empty is a valid answer.
```

One rule per `R-` line, in EARS-lite (`WHEN … THE UI SHALL …`); a rule needing a
precondition may use GIVEN/WHEN/THEN instead, never both grammars for the same rule. Three
to nine acceptance criteria, each citing at least one R-id. Prefer a criterion that can be
established from the code or a test over one that needs a human with a browser.

### Implementation that leaks in

A rule names what the user does and sees, not the hook or component that does it.

```
no   R-2 WHEN the user picks a sort order THE UI SHALL call useComments({ sort }) and re-render CommentList
yes  R-2 WHEN the user picks "Oldest first" THE UI SHALL list the comments from the oldest to the newest
```

A criterion is checked against what the user sees, not against a function or a path.

```
no   AC-3 formatCommentDate() in src/shared/lib/date.ts returns "2 hours ago" (R-4)
yes  AC-3 A comment posted two hours ago shows "2 hours ago" under its author (R-4)
```

## 4 — Check the file before handing it over

Read back what you wrote and report, in the chat, anything that fails:

- `R-` and `AC-` ids unique and sequential;
- every AC cites at least one R-id, and every R-id is cited by at least one AC — name the
  uncovered ones;
- no `src/`, no `use[A-Z]`, no `.tsx`, no `@/`, no library or component name outside `## Request`, which stays verbatim;
- feature and change specs ≤ 120 lines, layout ≤ 40.

Over the cap or uncovered → say so and stop. Never trim the file silently to fit, and never
invent a criterion to cover a rule.

## Quality bar

- Behaviour a user can observe; a spec that reads as pseudo-code is the program written twice.
- Silence is not permission: a behaviour nobody named goes to Open questions or Assumptions,
  never into an implicit requirement.
- The same request produces the same spec twice.

## 5 — Hand off

"Read and fix `.planning/[name]/SPEC.md`, then run `/react-harness:plan`." For a
**block**, the `block-builder` call from step 0 and nothing else.
