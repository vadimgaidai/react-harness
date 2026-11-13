---
name: plan
description: Turns `.planning/[name]/SPEC.md` into the HOW — one `PLAN.md` with modules in build order, each citing the acceptance criteria it serves, plus the sliced API contract, the design brief and a readiness check before implementation starts. Asks only what the codebase and the spec cannot answer. Use when a spec exists and the user wants modules, structure or a build order; the step between `/spec` and `/implement`.
disable-model-invocation: true
---

# Plan

You turn the WHAT into the HOW and produce **one** file. You write no production code —
`/react-harness:implement` does, reading what you wrote.

**One request = one PLAN.md**, even when it spans several modules: the implementer reads one
document.

## Inputs

- `.planning/[name]/SPEC.md` — authoritative for behaviour, UI states, permissions and
  acceptance criteria. Missing for a `feature` or `change`? Stop and say: "run
  `/react-harness:spec`". A `layout` may arrive with the light spec.
- The project's `CLAUDE.md` and `.claude/rules/`, and a structure skill when one is loaded.

Read the spec whole — it is capped at 120 lines for exactly this. Then check it before
planning against it: ids unique and sequential, every AC citing an R-id, every R-id cited.
An uncovered id is reported and stops the pass; the spec is the human's to fix.

PLAN.md never copies the spec. It cites `AC-` ids, and behaviour stays in one file.

## 1 — Ask only HOW questions the code cannot answer

`AskUserQuestion`, one question per turn, recommended answer first, never a batch.

- **Dependencies** — when the work could plausibly be solved by a third-party package, or by
  replacing or major-upgrading an installed one, the choice is a **blocking question in this
  pass**, never a decision the plan makes silently. Present 2–3 candidates — version, React
  compatibility, bundle cost, last release — and lead with a recommendation. "No new
  dependency — build on what's installed" is always one of the options. `implement` may not
  add what the plan does not name.
- **Collision** — a module with this name already exists: extend or rename.
- **A HOW ambiguity the spec legitimately leaves open** — optimistic update versus refetch
  when the spec only says the list updates. At most two of these; everything else becomes a
  plan decision, stated under `## Decisions`.

Everything else is read, not asked: the structure skill for placement, the sibling module by
path (named in the plan, outlined by `implement`, never read here), the installed primitives.

## 2 — Slice the contract (skip when the spec names no endpoint)

Follow the `api-contract` skill, with the endpoints the spec's **Data sources** lists:

```bash
node "${CLAUDE_PLUGIN_ROOT}"/skills/api-contract/scripts/contract-slice.mjs \
  <url-or-path> .planning/[name]/contract.md "GET /pet/{petId}" "POST /pet"
```

It writes exact request/response shapes with `$ref`s inlined — required vs optional, enums,
formats. `implement` reads that file and never the raw spec.

## 3 — Slice the design (skip when the spec's Design is "none")

Dispatch the `theme-sync` agent in **feature mode** on the frames the spec names. It writes
`.planning/[name]/DESIGN.md` — tokens, component map, layout, measurements, screenshots.

- **You never call Figma MCP tools yourself.** The payloads burn in the subagent.
- **You never map a design value to a Tailwind class or token yourself** — `theme-sync` reads
  the project's `@theme` first, and a class written from memory may not exist here. The
  plan's design sections cite `DESIGN.md` rows rather than restating them.

## 4 — Write `.planning/[name]/PLAN.md`

Lists and tables, no prose padding, no code samples.

```markdown
# PLAN: [name]

**Spec:** `.planning/[name]/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules
| # | Path | Role | Depends on | Serves |
|---|---|---|---|---|
| 1 | src/entities/comment | types, api, queries | — | AC-1, AC-2 |

Build in this order.

## Conventions to follow
The existing module this work mirrors (`path/to/module`), plus any structure skill that governs it.

## Contract
`.planning/[name]/contract.md` — authoritative for every shape. Source: <url>.
| Method | Path | Used by | Auth |

## Design
`.planning/[name]/DESIGN.md`, plus the node URL per UI block. "none" when there is no design.

## Per module

### `path/to/module`
- **Files**: what gets created
- **Types**: interfaces and unions, derived from the contract
- **Data layer**: queries / mutations, and what each mutation invalidates
- **Schemas**: field rules + defaults (forms only)
- **UI**: components, props, which primitives they wrap; the block's Figma node URL when one exists
- **Boundary**: what it exports; what it may import from
- **Proves**: the AC ids this module serves, and the spec's UI states and permission rules it renders

## Decisions
HOW choices the spec left open and how they were settled.

## Coverage
| AC | Modules | Evidence `verify` should expect |
|---|---|---|
| AC-1 | 1, 3 | static: query + list render |

## Out of scope
Explicit non-goals.

## Open questions
Anything still ambiguous. Empty is a valid answer.
```

A `layout` plan keeps the same shape with a block table as its modules and one Coverage row
per block.

## 5 — Readiness check

Run it before the hand-off and report it as one block. The first two block; the rest are
reported:

1. **Coverage both ways** — every AC maps to at least one module, every module serves at
   least one AC or is named infrastructure. Name the gaps.
2. **Contract versus spec** — an endpoint the spec names that the slice lacks, or a field the
   spec's behaviour needs that the contract has no source for. Name it; never guess it.
3. **Open questions in the spec** — list them; the user decides whether to proceed.
4. **Proportion** — a plan more than three times the spec's length is a smell; say so.

## 6 — Scaffold

If a structure skill ships a scaffolder, run it per module in build order. Otherwise skip —
the implementer creates files as it goes.

## Quality bar

- Unambiguous — the same spec and plan produce the same code twice.
- No invented shapes: anything API-shaped points at `contract.md`.
- No behaviour the spec does not carry; a new requirement discovered here goes back to
  `/react-harness:spec`, not into the plan.
- A block repeated across frames is one module, built once — per-block builders cannot see
  siblings, so dedup happens here or not at all.
- Never run a full build or lint to answer a planning question.

## 7 — Hand off

State the PLAN.md path, then: "Next: `/react-harness:implement`." A whole-theme
pass (`theme-sync` in theme mode) stays a separate, user-initiated run.
