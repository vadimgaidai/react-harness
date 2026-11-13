---
name: refine
description: Applies requested changes to a just-implemented unit of work — the step between `/implement` and `/review` for "I looked at it and want this different". Reads `.planning/[name]/` as the authority, classifies each remark (missed plan vs changed mind vs design mismatch vs new scope), fixes accordingly and keeps PLAN.md in sync so review verifies the current truth. Use when the user wants changes to what was just built, before or instead of a review.
---

# Refine

You change what `/implement` built, steered by what the user saw. Main session, no fan-out, the same conventions and the same authorities as `implement` — refining is not freeform chat that forgets the plan exists.

You are done when every user remark and every open `- [ ]` box in `VERIFY.md` and `REVIEW.md` is applied, refuted or declined with its one line; each of those files has frontmatter `status: done` (every box ticked) or `status: partial` (any left open, with the reason); the project's typecheck passes; and the Output below is written.

## Inputs

- `.planning/[name]/SPEC.md` when it exists — authoritative for behaviour and acceptance criteria. A remark that changes what the product does changes this file first.
- `.planning/[name]/PLAN.md` — the HOW being refined: modules, boundaries, decisions.
- `.planning/[name]/contract.md` — authoritative for shapes. Never re-fetch, never edit — it mirrors the server. If the server changed, re-slice with `api-contract`; that is not a refinement.
- `.planning/[name]/DESIGN.md` when it exists — authoritative for tokens, spacing, layout and measurements. Screenshots are read with `Read`; never call Figma MCP for anything it answers.

- `.planning/[name]/VERIFY.md` when it exists — `verify`'s failed criteria as `- [ ]` items, each with the criterion, the evidence and what is missing. Taken in the same way as a review item, and first: a criterion the spec states is not a judgement call.
- `.planning/[name]/REVIEW.md` when it exists — `review`'s findings as `- [ ]` items, style violations first, then engineering remarks. Each has four parts: `file:line` → problem → the rule, cited by skill and section, with the concrete consequence for an engineering remark → proposed change, sometimes with a fenced code block. Open questions sit under `## Open questions` as plain bullets, each with what would settle it. Findings are taken in as below, never applied blind and never pasted from the code block unchecked; open questions are settled with the user or the code, never tasks.

No `.planning/` folder for this work? Take the change as a direct brief against the project's conventions — and say the spec and plan are missing.

## Conventions before the first edit

Call the convention skills for what the change touches, through the `Skill` tool, before the first Write or Edit — the same route as `implement`; a skill already called in this session is not called again:

- Every `.ts` or `.tsx` file: `code-shape`, `typescript`.
- Every component or hook: `react`, `ui-conventions`, `error-handling`.
- A query, a mutation or the cache: `tanstack-query`.
- A form or a validation schema: `react-hook-form-zod`.
- A route, a loader or search params: `routing`.
- A test file: `react-testing`.

## 0 — Taking in VERIFY.md and REVIEW.md

A verify item names a criterion the change does not meet; a review item is a claim about the
code. Both are worked the same way, verify first. For each open box, in order:

1. **Read the whole item** before touching anything — a review item's four parts (`file:line`, problem, rule, proposed change) are one argument, and so are a verify item's criterion, evidence and what is missing.
2. **Verify it against the code as it is now.** Open the `file:line`; confirm the problem is there and the cited rule applies to the line as written (the helper it names exists, the second caller it says is missing is missing, the contract line or skill section it cites says that). An item the code refutes is marked `[x] refuted — <the line that proves it>` and left alone.
3. **Apply the fix**, one item at a time, the smallest change that keeps the behaviour; run the typecheck after each. Tick the box with one line naming what changed.
4. **Push back with evidence.** An item that would break behaviour, remove a designed state or contradict `PLAN.md` / `contract.md` is not applied: mark it `[x] declined — <reason, with the file:line or plan line>`. The diff and the tick line are the whole acknowledgement.
5. **Unclear item → stop and ask** before applying any of the others; items can depend on each other, and half an understanding is a wrong edit.

Blocking items (a failed criterion, a red check, a contract violation) first, then simple ones, then the ones that restructure. An open question is answered — by a line of code you can quote, or by asking — and recorded under it; it is never turned into an edit on its own. Then set the frontmatter `status` of each file as the done criterion above says.

Three calls that are easy to get wrong. A tick keeps the item's line and adds what happened to it on that same line.

Fixed — the tick names what changed, with `file:line`.

```
no   - [x] AC-3 — fail — static — nothing handles 409; R-5 requires a conflict message — fixed
yes  - [x] AC-3 — fail — static — nothing handles 409; R-5 requires a conflict message — fixed: src/features/comments/ui/comment-form.tsx:52 shows t("comments.conflict") on a 409
```

Refuted — the proof is a line of code, not an opinion about the finding.

```
no   - [x] refuted — the hook is needed
yes  - [x] refuted — src/features/comments/model/use-comment-draft.ts:9 is read by comment-form.tsx:14 and reply-form.tsx:11, so it is not a one-caller wrapper
```

Declined — the reason cites the plan, spec or contract line it would break.

```
no   - [x] declined — not needed
yes  - [x] declined — PLAN.md Decisions "the comment list owns its empty state"; removing comment-list.tsx:71 drops the designed empty state for AC-5
```

## 1 — Classify each remark (the user's)

| Kind | Test | Action |
|---|---|---|
| **Missed** | The plan already says it; the implementation didn't do it | Fix the code. No plan edit. |
| **Changed mind, behaviour** | The spec says A; the user now wants B on screen | Fix the code **and** update `SPEC.md` — the `R-` rule, the UI state, the permission, the affected `AC-` — plus the plan's Coverage row when the mapping moves. |
| **Changed mind, structure** | The behaviour stands; the plan's HOW changes | Fix the code **and** update `PLAN.md` only — the module section, boundary or decision the change touches. |
| **Design mismatch** | "doesn't match the design" | Check `DESIGN.md` first: a coding error → fix it; a recorded NO MATCH / gap → that is a pending decision, ask the user, don't guess. A presentational block wrong at the markup level → one `block-builder` call with its node URL; never a Figma fetch in this session. |
| **New scope** | A new module, endpoint, role rule — or any dependency change | Not a refinement. Name it and route it: new behaviour → "run `/react-feature-workflow:spec`"; a new module for behaviour the spec already has → "run `/react-feature-workflow:plan`". |

A message that mixes kinds gets split: do the refinements, list what you routed away.

## Rules

`implement`'s rules apply unchanged — the convention route above, a structure skill wins placement (sibling shape is the fallback), no dependency the plan does not name, tokens over raw values, `.d.ts` over prose. Two additions:

- The smallest change that satisfies the remark. A refinement that rewrites a working module is a rewrite, not a refinement.
- Every `SPEC.md` and `PLAN.md` edit is announced as old → new, never silent — both are shared state between the commands.

## Verify

The project's typecheck. Nothing heavier.

## Output

Files changed; every `SPEC.md` and `PLAN.md` edit as old → new; anything routed to `spec`, `plan` or `api-contract`, with the reason. Then: "Next: `/react-feature-workflow:verify`" while a criterion is still open, otherwise "Next: `/react-feature-workflow:review`" — or another pass here if more comes up.
