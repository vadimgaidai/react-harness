# Getting started

## Install

```bash
claude plugin marketplace add vadimgaidai/react-harness
claude plugin install react-harness@vadimgaidai --scope project
claude plugin install feature-folders@vadimgaidai --scope project         # feature, page and layout modules plus global buckets
claude plugin install feature-sliced-design@vadimgaidai --scope project   # Feature-Sliced Design layers
```

One structure plugin per project; they disagree on what `src/` should look like. Inside a session, `/plugin` opens a picker. Choose "Install for all collaborators on this repository (project scope)".

## Scope

Without `--scope project` the install defaults to `user` scope and the plugins load in every repository you open. For `feature-sliced-design` that means its hooks block `src/components/button.tsx` in a project that is not FSD. `marketplace add` has no scope flag; the project-scope install records the marketplace in the repository.

The install writes this to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/react-harness" } }
  },
  "enabledPlugins": {
    "react-harness@vadimgaidai": true,
    "feature-folders@vadimgaidai": true
  }
}
```

Commit it. Teammates then see the plugins as "not installed" and run the install lines once. [react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a repository set up this way.

## Requirements

- `node` for the hooks of all three plugins.
- A React project. Elsewhere the convention skills never load.
- The Figma MCP server for `theme-sync` and `block-builder`. Without it `implement` builds all UI itself.

## Design plugins

The harness shapes the code, not the look. Add whatever design tooling you like next to it. We recommend Anthropic's `frontend-design` plugin for a fresh UI and the harness's Figma agents for a design that already exists; the rules keep what either writes on shadcn primitives, semantic tokens and the project's structure.

## First run

Ask for a feature with no command:

```
add a settings page with a profile form: name, email, avatar upload, saved through PATCH /me
```

The session-start hook has already named the convention skills to call; the structure hook checks every new file. Read what landed against the structure in the plugin's README.

Then a review of a branch that already exists:

```
/react-harness:review
```

No spec, no `.planning/` folder. It reports against `CLAUDE.md`, `.claude/rules/` and the convention skills, and edits nothing.

Then, when you want a spec you can read before any code exists:

```
/react-harness:spec add comments to articles
```

Read `.planning/comments/SPEC.md` and fix it, then run `plan`, `implement`, `verify`, `review`, `refine` one at a time, any model you choose per stage. This takes more time and tokens than just asking and gives you every step to check. For a change you can say in one sentence, or for an agent running without you, `/react-harness:autopilot` runs the same stages in one go.

To keep the route to the skills in your repository as well, add the lines from the [plugin README](../plugins/react-harness/README.md#convention-skills) to the project's own `CLAUDE.md`.
