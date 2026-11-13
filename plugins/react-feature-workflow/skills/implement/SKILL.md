---
name: implement
description: Implements a planned unit of work end-to-end in one pass — types, data layer, schemas, UI, wiring — from `.planning/[name]/SPEC.md` and `PLAN.md`. Use when a `.planning/[name]/PLAN.md` exists and the user or `autopilot` asks to build it; a request with no plan is coded directly with the convention skills. Invoke it before reading the plan or exploring the code — it says what to read and in what order. Runs in the main session; do not fan out to subagents.
---

# Implement

You implement a whole unit of work in one pass: every layer of every module in the plan, in build order, in this session.

You are done when every module in the plan is built in build order, the project's typecheck passes or cannot run, and the Output report is written.

## Hard rules

Call the convention skills through the `Skill` tool before the first Write or Edit of the layer they govern; they hold the house rules, and the session-start text names the same route:

- Every `.ts` or `.tsx` file: `code-shape`, `typescript`.
- Every component or hook: `react`, `ui-conventions`, `error-handling`.
- A query, a mutation or the cache: `tanstack-query`.
- A form or a validation schema: `react-hook-form-zod`.
- A route, a loader or search params: `routing`.
- A test file: `react-testing`.

A skill already called in this session is not called again. A `structure` skill, when one is installed, decides placement.

When sources disagree, follow the winner named here and report the deviation in the output:

- `contract.md` disagrees with the plan's prose: **the contract wins** — say so, then follow it.
- The plan disagrees with `SPEC.md` about behaviour: **the spec wins** — build the behaviour the spec states.
- The plan's prose disagrees with an installed package's own types (`.d.ts`): **the types win** — same precedence as `contract.md` over prose.

**Do not delegate layers to subagents.** Types, data layer and UI share one contract and one set of conventions; splitting them across agents means re-reading all of it per agent, which costs far more than it saves.

## Inputs

- `.planning/[name]/SPEC.md` — **authoritative for behaviour**: the `R-` rules, UI states, permissions, unchanged behaviour and the acceptance criteria the work is judged by. Read it whole; it is capped for that. The plan cites `AC-` ids rather than copying them, so a behaviour question is answered here, never from the plan's prose.
- `.planning/[name]/PLAN.md` — the HOW: modules in build order, what each serves, boundaries, decisions. Missing? Ask the user to run `/react-feature-workflow:spec` and then `/react-feature-workflow:plan`, or take a direct brief for a small change. A `PLAN.md` with its own acceptance criteria and no `SPEC.md`: use those criteria and say the spec is missing; do not stop for it.
- `.planning/[name]/contract.md` — **authoritative for every request/response shape.** Read it; never open the raw OpenAPI/Swagger file it names as its `Source:` — not with `Read`, not with `cat` or `jq` — and never invent a field it does not list. The slice already carries every field, required flag, enum and format the spec has for these endpoints.
- `.planning/[name]/DESIGN.md` when the plan names a design — **authoritative for tokens, spacing, layout and measurements. Never call Figma MCP for anything it answers; its saved screenshots are read with `Read`, not re-fetched.** The only Figma calls during implementation are `block-builder` delegations — one per presentational block; a static shell needs the real node payload, a slice can't replace it. A value flagged "no match" is a real gap: surface it, don't invent one.

## Presentational blocks from Figma

The one exception to not delegating: when a module's UI entry carries a Figma node URL, the Figma MCP server is connected, **and the block is presentational** — a landing section, a card, a header, where props are the whole boundary — delegate its markup: pass the node URL, the target path from the plan, and the component's props (from the plan and `contract.md`). This is not splitting a layer — it is keeping the Figma payload out of this session. When the plan has several such blocks and none depends on another's output, launch all their `block-builder` delegations in one message so they run concurrently, then wire them once every report is back. You still own types, data layer, wiring, exports and routes.

UI that is inseparable from data and state — a table's cells, a chat's message list, a multi-step form — you build yourself from the plan and `DESIGN.md`, node URL or not: a delegated static shell of it costs more to rework than it saves. Same when Figma MCP isn't connected or there is no node URL.

## Learn the conventions before writing

In this order, cheapest first:

1. The project's `CLAUDE.md` and `.claude/rules/` — project facts and machine-enforced rules.
2. The convention skills — the route under Hard rules, before the first Write or Edit of each layer.
3. **The sibling module the plan names** — outlined first, then the files you mirror read whole:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}"/skills/implement/scripts/sibling-outline.sh src/entities/article
   ```

   The outline is a map, not a substitute: it prints the folder shape, the barrel, short files whole and only the first `export` line of each longer file, so the bodies of long files are missing (error handling, query options, invalidation, effects, markup, private helpers). From it, pick the files with the same role as each file you are about to write (a query hook before a query hook, a form before a form) and `Read` them whole; skip the rest. A file the outline already printed whole is not read again. **Its folder shape is part of the convention**: subfolders (`components/`, `hooks/`), where types and constants live, what the barrel exports. Mirroring a sibling's runtime pattern while flattening its structure is a defect. (When a structure skill is loaded, it decides placement instead — the sibling rule is the fallback.)

Of a skill's `references/`, open only the file that matches what you are about to write, never all of them up front.

## Order (per module, in the plan's build order)

1. Constants and enumerations.
2. Types — derived from `contract.md` exactly: required vs optional, enums, formats, nullability.
3. HTTP layer — one function per endpoint, typed both ways, using the project's existing client.
4. Data layer — queries / mutations, wired to the cache keys the plan names.
5. Validation schemas (forms).
6. UI — every state the plan lists (loading / empty / error) and every role rule. Localized text where the project is localized. A **presentational** block with a Figma node URL goes to `block-builder` — one call per block, props stated in the call; integrate what it wrote, then add the loading/empty/error states and role rules the design could not show it. Logic-bound UI you build yourself (see Presentational blocks from Figma).
7. Public exports / barrels.
8. Routes and pages last, once the modules they mount exist.

## Rules

- Domain types, lookup maps and magic constants belong in the module's model layer, not inline in components. Only a component's own props type stays local.
- A file does one thing (fetch / map / render). Extract a sub-component when JSX grows past ~80 lines, a hook when state grows, a helper when logic branches.
- No `any`. No values guessed where a contract, token or existing constant exists.
- Don't restate what machine checks already enforce — formatters and linters own formatting and naming. Never add a lint-disable to get past one.
- Before creating a provider, context, hook or helper **inside** a feature/module folder, ask where the repo already keeps that role: the structure skill's layer rules when one is loaded, an existing top-level bucket (`src/providers/`, `src/contexts/`, `src/hooks/`, …) otherwise. Never invent a second home for a role that has one.
- Never add, replace or major-upgrade a dependency the plan does not name. Needing one mid-implementation is a blocking question to the user, not a `pnpm add`.

## Verify

Run the project's typecheck. Do not run a full build or lint unless the project has no other check — pre-commit hooks and CI own those. Then look at each screen you built once, as `ui-conventions` says, and fix what looks wrong; a full walk of every flow is `/react-feature-workflow:verify`'s `manual` tier, and anything you could not see is reported as such rather than claimed. When the typecheck passes, write the report and stop. A typecheck that cannot run (dependencies not installed, registry unreachable) is not a failure: do not install packages or fall back to a global `tsc`; say why in the report and stop.

## Output

Files created/edited, anything newly required (a package to install, a UI primitive to add), and anything in the plan you did **not** build, with the reason. Then: "Next: `/react-feature-workflow:verify`" — or `/react-feature-workflow:refine` first, when what you see needs changing.
