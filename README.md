# React Harness

A harness for [Claude Code](https://claude.com/claude-code) that makes it write React applications in one structure. It is not a prompt you paste: hooks and skills sit between you and the model on every session, so a plain request for a feature comes out as the project would have been laid out by one experienced lead, and a file in the wrong place is refused before it is written.

The harness is tuned for the structure of the application and the code inside it. It does not decide how the app looks. Add any design tooling you like on top; we recommend Anthropic's `frontend-design` plugin for a new UI and the harness's own Figma agents for an existing design.

## How the harness works

- **A hook routes the rules.** At session start, and again when a code-writing subagent starts, a hook tells Claude which rule skills to load for the work at hand: a component, a query, a form, a route, a test. You type the task; the route is already there.
- **Skills carry the rules.** The `react-harness` plugin ships nine convention skills, one per layer of the stack. They load into the session only when their layer is touched, so the rules for forms do not sit in the context while a route is written. They are plain markdown your team can read and change.
- **A hook guards the structure.** `feature-folders` or `feature-sliced-design` holds the folder layout. Its skill answers where a file goes; its hook refuses a new file outside the layout, a wrong filename, a barrel import or a domain type inside a UI file, before the write lands. Pick the one that matches your project.
- **Stages are there when you want them.** Six spec-driven commands and one automatic loop, all started by you, never by the model on its own. See [Three ways to work](#three-ways-to-work).

## The nine skills

| Skill | What it keeps |
|---|---|
| `react` | State in the lowest place that reads it, no effect for what render can compute, one Suspense boundary per region |
| `tanstack-query` | One way to load data: `useSuspenseQuery` inside a `QueryBoundary`, keys from a factory, a mutation that owns its cache writes and toasts |
| `routing` | Filters, sort and page live in the URL and are parsed once at the router, never copied into state |
| `typescript` | Types come from the API contract, input is narrowed once at the boundary, no `as`, no `any`, no `enum` |
| `react-hook-form-zod` | One schema file, `z.infer` as the form type, every field through `Controller`, the submit goes to a mutation |
| `error-handling` | Every error has one owner: the boundary, the mutation's `onError` or the form's `setError`, never two toasts |
| `ui-conventions` | shadcn primitives over hand-rolled markup, semantic tokens, right-to-left-safe spacing, every string through `t()` |
| `code-shape` | Two parameters then an options object, guard clauses, no nested ternaries, no comments |
| `react-testing` | Tests find elements by role, run a real `QueryClient` with the network mocked, and prove what the user sees |

Each rule as a before-and-after pair: [docs/DESIGN.md](./docs/DESIGN.md#what-the-rules-change-file-by-file). A whole page with and without the harness, file by file: [docs/USE-CASES.md](./docs/USE-CASES.md#a-crypto-dashboard-from-one-sentence). The structure hook blocks a misplaced file; the code patterns are followed by the model, not enforced by a linter, so a single line can still miss one and `review` is there to catch it.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-harness
claude plugin install react-harness@vadimgaidai --scope project
```

Then one structure plugin:

```bash
claude plugin install feature-folders@vadimgaidai --scope project         # feature, page and layout modules plus global buckets
claude plugin install feature-sliced-design@vadimgaidai --scope project   # Feature-Sliced Design layers
```

`--scope project` matters. Without it the plugins load in every repository you open. Details in [docs/GETTING-STARTED.md](./docs/GETTING-STARTED.md).

## Three ways to work

**Just ask.** This is the default. Type the task, no command. The hook names the skills to load, the structure hook checks every new file, and the code comes out in the patterns above. Time and tokens are about the same as plain Claude Code.

```
add a staking tab to the portfolio page: positions, APR, pending rewards, a claim button per row
```

**Manual stages.** The usual spec-driven workflow: six commands, each writing a file the next one reads. You start every stage yourself, read `SPEC.md` before a module exists, correct it, and can run each stage in a different model. This costs more time and tokens than just asking; what you get back is control over every step.

```
/react-harness:spec       .planning/<name>/SPEC.md    behaviour and acceptance criteria with ids
/react-harness:plan       PLAN.md + contract.md       modules in build order, each citing its criteria
/react-harness:implement  code                        reads the spec and the plan, builds in order
/react-harness:verify     VERIFY.md                   every criterion pass, fail or unverifiable, with evidence
/react-harness:review     REVIEW.md                   rule violations and needless complexity, never an edit
/react-harness:refine     code                        applies what verify and review found
```

`review` also works on any branch with no spec at all.

**The automatic loop.** One command runs the same stages without stopping. It fits a small change you can say in a sentence, and it fits an autonomous agent that gets a task and has to return checked code with a report, with no human in the middle.

```
/react-harness:autopilot show the token symbol next to amounts in the activity list
```

It asks at most two questions, writes a short `SPEC.md` and `PLAN.md`, builds through `implement`, then runs `verify`, `refine` and `review` until the criteria pass. The order is not the model's to choose: a hook reads `VERIFY.md`, `REVIEW.md` and a `LOOP.md` state file and allows only the next stage.

```
implement ──► verify ──failed──► refine ──► verify …   (each verify is a round, 4 at most)
                 │
               ready
                 ▼
              review ──► report      "Say refine to apply the review findings"
```

Four exits: `finished` when nothing is left, `stuck` when the same criteria fail two rounds in a row, `capped` at the fourth round, `stopped` when the model hands over a red check it cannot settle. A code edit after a `verify` forces a new `verify`, and the turn cannot end while a stage is left. More than five criteria, a new screen, a Figma design or a new dependency send the request to `spec` instead.

The cost is control: you see the spec after the code exists, and every stage runs in the same model. In an unattended run it asks nothing and records its decisions as assumptions; review findings left open at the end are applied only on a `refine` reply.

Worked examples with what lands on disk: [docs/USE-CASES.md](./docs/USE-CASES.md). The decisions behind the harness: [docs/DESIGN.md](./docs/DESIGN.md).

## Plugins

- [react-harness](./plugins/react-harness): the core, always installed: the route hook, nine convention skills, the six stage commands, `autopilot`, three Figma and bug agents.
- [feature-folders](./plugins/feature-folders): global buckets plus feature, page and layout modules; a hook refuses a new file outside them and leaves an old tree alone.
- [feature-sliced-design](./plugins/feature-sliced-design): the same for Feature-Sliced Design layers, plus the import direction between them.

Contributing and release rules: [CONTRIBUTING.md](./CONTRIBUTING.md). MIT.
