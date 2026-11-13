# React Feature Workflow

Spec-driven development for React features in [Claude Code](https://claude.com/claude-code). One command runs the stages and stops for you to read the spec; each stage is also a command of its own, and `review` works on any branch with no spec at all.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
```

Commit the `.claude/settings.json` it writes. Scope and requirements: [Getting started](../../docs/GETTING-STARTED.md).

## Try it on the branch you have

```
/react-feature-workflow:review
```

No spec, no plan, no `.planning/` folder. It reads the diff of your branch file by file against `CLAUDE.md`, `.claude/rules/` and the convention skills below, runs your typecheck, lint and tests, and reports each finding with the rule it cites and the line. It edits nothing.

## Stages

Each is its own command, run in a fresh session, reading the files the one before it wrote. Prefix the `spec` request with `change:` for an edit to a module that exists, `layout:` for a page from Figma. Worked examples: [Use cases](../../docs/USE-CASES.md).

| Command | Reads | Writes |
|---|---|---|
| `/react-feature-workflow:autopilot` | a small change, at most two questions | a short `SPEC.md` and `PLAN.md` in the same formats, then `implement`, `verify` and `review` in the same run |
| `/react-feature-workflow:spec` | your request, point lookups in the code | `.planning/<name>/SPEC.md`: behaviour rules with ids, UI states, permissions, failure cases, acceptance criteria, assumptions |
| `/react-feature-workflow:plan` | `SPEC.md`, `CLAUDE.md`, the structure skill | `PLAN.md`: modules in build order, each citing the criteria it serves; `contract.md` cut from your OpenAPI file; `DESIGN.md` from Figma |
| `/react-feature-workflow:implement` | `SPEC.md`, `PLAN.md`, `contract.md`, `DESIGN.md`, one sibling module outlined | code, then your typecheck |
| `/react-feature-workflow:verify` | `SPEC.md`, the plan's coverage table, the diff | `VERIFY.md`: each criterion pass, fail or unverifiable, with the evidence: a command that ran, a `file:line`, or manual steps |
| `/react-feature-workflow:review` | the diff file by file, the rules the project states, the convention skills | `REVIEW.md` when a `.planning/<name>/` folder exists: style violations with the rule and the line, engineering remarks with the argument |
| `/react-feature-workflow:refine` | `VERIFY.md`, `REVIEW.md`, your remarks | code; `SPEC.md` when the behaviour changed, `PLAN.md` when only the structure did |

Nothing edits code except `implement` and `refine`. `verify` and `review` report. The spec wins over the plan on behaviour and the contract wins on shapes; both deviations are reported, never silently resolved.

## Convention skills

A hook at session start, and at the start of a subagent that writes code, names them by the route below; `implement` and `refine` name them the same way, and `review` reads their `references/reviewing.md` when it starts.

| Skill | What it does |
|---|---|
| `react` | Decides where state lives, when an effect is needed at all, when memoization is worth it, and how a route or a heavy widget is split and wrapped in Suspense. |
| `tanstack-query` | Keeps queries and mutations consistent with the project's shared client: how a key is built, when a query is dependent or derived, what a mutation invalidates. |
| `ui-conventions` | Keeps components on shadcn primitives and semantic tokens so they look right in both themes, and decides when a primitive is extended rather than copied. |
| `react-hook-form-zod` | Builds forms the way the project does: the schema in its own file, the resolver as the only validation, the form values and the schema output kept identical. |
| `code-shape` | Holds the house style for plain code: how much of it there should be, how a function takes its parameters, how branching reads, when a loop is doing repeated work. |
| `typescript` | Keeps types honest: narrowed once at the boundary, derived from the contract instead of written twice, impossible states made unrepresentable. |
| `error-handling` | Assigns each error one owner in this stack and says what a catch is allowed to do with it, so failures are neither duplicated nor swallowed. |
| `routing` | Keeps URL state as the source of truth — filters and pagination restored from the URL, a loader and a query never holding two copies of the same data, nested routes with their own loading boundary. |
| `react-testing` | Says what a test should prove — the observable result, not an implementation detail — and reviews whether one actually does. |

To keep the route in your repository as well, add these lines to the project's own `CLAUDE.md` (a `CLAUDE.md` inside the plugin is not loaded):

```markdown
Before the first Write or Edit of code, call the react-feature-workflow skills:
- Every `.ts` or `.tsx` file: `code-shape`, `typescript`.
- Every component or hook: `react`, `ui-conventions`, `error-handling`.
- A query, a mutation or the cache: `tanstack-query`.
- A form or a validation schema: `react-hook-form-zod`.
- A route, a loader or search params: `routing`.
- A test file: `react-testing`.
```

## Agents and hooks

- `@react-feature-workflow:block-builder <node-url> into <path>` builds one presentational block from Figma.
- `@react-feature-workflow:theme-sync <figma-url>` maps Figma variables onto shadcn tokens, light and dark.
- `@react-feature-workflow:bug-fixer <description>` reproduces one bug and fixes it with the smallest change.

A `SessionStart` hook, and the same text on `SubagentStart` for code-writing subagents, names the convention skills to call before the first edit. `loop-guard` runs the verify → refine → review loop of `autopilot` while `.planning/<name>/LOOP.md` is `running`: it lets only the next stage run, logs every `verify`, `refine` and `review` call in `LOOP.md`, refuses a `verify` or `refine` past `max_iterations` (4), ends the loop as `stuck` when the same criteria fail two rounds in a row, asks for a new `verify` after a code edit, takes only `status: stopped` as an edit of `LOOP.md`, and does not let the turn end while `VERIFY.md` and `REVIEW.md` say a stage is left. Without a running `LOOP.md` it does nothing. A `PostToolUse` hook formats every file written through Write or Edit with the project's own Prettier (`node_modules/.bin/prettier`), and does nothing when the project has none. Files written through the shell are left to the project's pre-commit formatting (husky, lint-staged).

## Requirements

- `node` for the hooks. Nothing else: the three hook scripts are plain Node, with no `jq` and no shell.
- The Figma MCP server for `theme-sync` and `block-builder`. Without it `implement` builds all UI itself.
- A React project for the convention skills. Elsewhere they never load and the workflow runs as is.

MIT. Part of [React Feature Kit](../../README.md).
