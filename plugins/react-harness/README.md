# React Harness

The core of [React Harness](../../README.md) for [Claude Code](https://claude.com/claude-code): nine convention skills that load while Claude writes the matching layer, so a plain request comes out in the house style. Pair it with a structure plugin (`feature-folders` or `feature-sliced-design`) for the folders. The look is yours to add on top, for example with Anthropic's `frontend-design` plugin or the Figma agents here. The stage commands below are optional and started by you only: the usual spec-driven workflow when you want control over every step, and `autopilot` when you want the same stages run on their own, for a small change or an autonomous agent.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-harness
claude plugin install react-harness@vadimgaidai --scope project
```

Commit the `.claude/settings.json` it writes. Scope and requirements: [Getting started](../../docs/GETTING-STARTED.md).

## Just ask

This is the default and needs no command. Type the task. A hook at session start has already told Claude which of the nine skills below to load for a component, a query, a form, a route or a test, and the same hook reaches any subagent that writes code. With a structure plugin installed, every new file is checked against the folder layout before it is written.

```
add a staking tab to the portfolio page: positions, APR, pending rewards, a claim button per row
```

Time and tokens are about the same as plain Claude Code. What you do not get is a document to check the result against: the spec was in your head, and `review` is the only check on the code.

```
/react-harness:review
```

`review` works on any branch, with or without a spec. It reads the diff file by file against `CLAUDE.md`, `.claude/rules/` and the nine skills, runs your typecheck, lint and tests, and reports each finding with the rule and the line. It edits nothing.

## Manual stages

For a large task where you want to control the process: the usual spec-driven workflow as six commands, each writing a file the next one reads. You start every stage yourself, in a fresh session if you like, so you read and correct `SPEC.md` before a module exists, check `PLAN.md` before any code, and can run planning in one model and implementation in another. `verify` and `review` fork their own context and never see the build.

The cost is time and tokens: every stage reads the files the one before it wrote, and you are in the loop between them. For a change you can say in one sentence, this is more ceremony than the change deserves.

| Command | Reads | Writes |
|---|---|---|
| `/react-harness:spec` | your request, point lookups in the code | `.planning/<name>/SPEC.md`: behaviour rules with ids, UI states, permissions, failure cases, acceptance criteria, assumptions |
| `/react-harness:plan` | `SPEC.md`, `CLAUDE.md`, the structure skill | `PLAN.md`: modules in build order, each citing the criteria it serves; `contract.md` cut from your OpenAPI file; `DESIGN.md` from Figma |
| `/react-harness:implement` | `SPEC.md`, `PLAN.md`, `contract.md`, `DESIGN.md`, one sibling module outlined | code, then your typecheck |
| `/react-harness:verify` | `SPEC.md`, the plan's coverage table, the diff | `VERIFY.md`: each criterion pass, fail or unverifiable, with the evidence: a command that ran, a `file:line`, or manual steps |
| `/react-harness:review` | the diff file by file, the rules the project states, the convention skills | `REVIEW.md` when a `.planning/<name>/` folder exists: style violations with the rule and the line, engineering remarks with the argument |
| `/react-harness:refine` | `VERIFY.md`, `REVIEW.md`, your remarks | code; `SPEC.md` when the behaviour changed, `PLAN.md` when only the structure did |

Prefix the `spec` request with `change:` for an edit to a module that exists, `layout:` for a page from Figma. Nothing edits code except `implement` and `refine`. The spec wins over the plan on behaviour and the contract wins on shapes; both deviations are reported, never silently resolved. Worked examples: [Use cases](../../docs/USE-CASES.md).

## The automatic loop

For work that runs without you watching: a small change you can say in a sentence, or an agent that gets a task in the background and has to return checked code with a report.

```
/react-harness:autopilot show the token symbol next to amounts in the activity list
```

One command runs the same stages in one go: at most two questions, a short `SPEC.md` and `PLAN.md`, `implement`, then `verify` → `refine` → `review` until the criteria pass. The order is not the model's to choose. A hook reads `VERIFY.md`, `REVIEW.md` and a `LOOP.md` state file and allows only the next stage; each `verify` is a round, four at most; the same criteria failing twice in a row end the loop as `stuck`; a code edit after a `verify` forces a new one; the turn cannot end while a stage is left. The run ends with a report: criteria by verdict, the review's counts, the rounds, every deviation a stage reported.

The cost is control: you see the spec after the code exists, not before, and the loop does not pick a different model per stage. In an unattended run (headless `claude -p`, a background agent) it asks nothing: it takes the answer it would have recommended and records it under `## Assumptions`. One thing to know: when the loop finishes with review findings open, applying them takes one more reply (`refine`); an agent that does not answer ends with the findings listed in `REVIEW.md`, not applied. Requests that are too big for the loop (more than five criteria, a new screen, a Figma design, a new dependency) are sent to `spec` and the run stops there.

## Convention skills

A hook at session start, and at the start of a subagent that writes code, names them by the route below; `implement` and `refine` name them the same way, and `review` reads their `references/reviewing.md` when it starts.

| Skill                 | What it does                                                                                                                                                                                          |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `react`               | Decides where state lives, when an effect is needed at all, when memoization is worth it, and how a route or a heavy widget is split and wrapped in Suspense.                                         |
| `tanstack-query`      | Keeps queries and mutations consistent with the project's shared client: how a key is built, when a query is dependent or derived, what a mutation invalidates.                                       |
| `ui-conventions`      | Keeps components on shadcn primitives and semantic tokens so they look right in both themes, and decides when a primitive is extended rather than copied.                                             |
| `react-hook-form-zod` | Builds forms the way the project does: the schema in its own file, the resolver as the only validation, the form values and the schema output kept identical.                                         |
| `code-shape`          | Holds the house style for plain code: how much of it there should be, how a function takes its parameters, how branching reads, when a loop is doing repeated work.                                   |
| `typescript`          | Keeps types honest: narrowed once at the boundary, derived from the contract instead of written twice, impossible states made unrepresentable.                                                        |
| `error-handling`      | Assigns each error one owner in this stack and says what a catch is allowed to do with it, so failures are neither duplicated nor swallowed.                                                          |
| `routing`             | Keeps URL state as the source of truth — filters and pagination restored from the URL, a loader and a query never holding two copies of the same data, nested routes with their own loading boundary. |
| `react-testing`       | Says what a test should prove — the observable result, not an implementation detail — and reviews whether one actually does.                                                                          |

To keep the route in your repository as well, add these lines to the project's own `CLAUDE.md` (a `CLAUDE.md` inside the plugin is not loaded):

```markdown
Before the first Write or Edit of code, call the react-harness skills:

- Every `.ts` or `.tsx` file: `code-shape`, `typescript`.
- Every component or hook: `react`, `ui-conventions`, `error-handling`.
- A query, a mutation or the cache: `tanstack-query`.
- A form or a validation schema: `react-hook-form-zod`.
- A route, a loader or search params: `routing`.
- A test file: `react-testing`.
```

## Agents and hooks

- `@react-harness:block-builder <node-url> into <path>` builds one presentational block from Figma.
- `@react-harness:theme-sync <figma-url>` maps Figma variables onto shadcn tokens, light and dark.
- `@react-harness:bug-fixer <description>` reproduces one bug and fixes it with the smallest change.

A `SessionStart` hook, and the same text on `SubagentStart` for code-writing subagents, names the convention skills to call before the first edit.

`loop-guard` is the state machine behind the automatic loop above; it reads `.planning/<name>/LOOP.md` and does nothing while no loop is `running`. A `PostToolUse` hook formats every file written through Write or Edit with the project's own Prettier (`node_modules/.bin/prettier`), and does nothing when the project has none. Files written through the shell are left to the project's pre-commit formatting (husky, lint-staged).

## Requirements

- `node` for the hooks. Nothing else: the three hook scripts are plain Node, with no `jq` and no shell.
- The Figma MCP server for `theme-sync` and `block-builder`. Without it `implement` builds all UI itself.
- A React project for the convention skills. Elsewhere they never load and the workflow runs as is.

MIT. Part of [React Harness](../../README.md).
