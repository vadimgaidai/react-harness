# React Feature Kit

Spec-driven development for React in [Claude Code](https://claude.com/claude-code). Three plugins: a workflow that builds a feature from a spec, and two structure plugins that keep files where the project says they go.

## The problem

One long chat produces one big diff and nothing to check it against. The spec was in your head, the plan was in the model's, and by the time you review there is no document that says what "done" meant.

The kit splits that chat into stages. Each stage is a command that writes a file, and the next one reads it.

```
/spec       .planning/<name>/SPEC.md       what the user sees, acceptance criteria with ids
/plan       PLAN.md + contract.md          modules in build order, each citing the criteria it serves
/implement  code                           reads the spec and the plan, builds in order
/verify     VERIFY.md                      every criterion: pass, fail or unverifiable, with evidence
/review     REVIEW.md                      code rules, needless complexity, wasted work
/refine     code                           applies what verify and review found, one item at a time
```

You read and fix `SPEC.md` before a single module exists. `verify` and `review` run in subagents that never saw the build. Request and response shapes come from your OpenAPI file, cut down to the endpoints the spec names. Figma frames are read by subagents, so their payload never lands in your session.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
```

Then one structure plugin, if the project has a structure to enforce:

```bash
claude plugin install feature-sliced-design@vadimgaidai --scope project   # Feature-Sliced Design architecture
claude plugin install feature-folders@vadimgaidai --scope project         # modular architecture (feature folders)
```

`--scope project` matters. Without it the plugins load in every repository you open. Details in [docs/GETTING-STARTED.md](./docs/GETTING-STARTED.md).

## What to type

```bash
# a review of the branch you are on — no spec, nothing to set up
/react-feature-workflow:review

# a feature with data, forms or state: spec, then plan, implement, verify, review
/react-feature-workflow:spec add comments to articles

# a change to a module that exists
/react-feature-workflow:spec change: paginate the comment list

# a small change: short spec and plan, the code, verify and review, one command
/react-feature-workflow:autopilot show the token symbol next to amounts

# a landing page from Figma — theme-sync once, then spec layout: …
@react-feature-workflow:theme-sync <figma-url>

# one block from a Figma frame
@react-feature-workflow:block-builder <node-url> into src/widgets/hero

# a bug fixed
@react-feature-workflow:bug-fixer the form submits twice
```

Worked examples with what lands on disk: [docs/USE-CASES.md](./docs/USE-CASES.md). Why it is shaped this way: [docs/DESIGN.md](./docs/DESIGN.md).

## Plugins

- [react-feature-workflow](./plugins/react-feature-workflow): `feature` and the six stage commands, nine convention skills that load while Claude writes the matching layer, three Figma and bug agents.
- [feature-sliced-design](./plugins/feature-sliced-design): hooks that reject a file on the wrong layer, a wrong filename, a barrel import or an upward import before it is written.
- [feature-folders](./plugins/feature-folders): the same for projects without layers: global buckets plus feature, page and layout modules. Blocks new files only, so an old tree is left alone.

Contributing and release rules: [CONTRIBUTING.md](./CONTRIBUTING.md). MIT.
