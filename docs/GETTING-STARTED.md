# Getting started

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
claude plugin install feature-sliced-design@vadimgaidai --scope project   # Feature-Sliced Design architecture
claude plugin install feature-folders@vadimgaidai --scope project         # modular architecture (feature folders)
```

Inside a session, `/plugin` opens a picker. Choose "Install for all collaborators on this repository (project scope)".

## Scope

Without `--scope project` the install defaults to `user` scope and the plugins load in every repository you open. For `feature-sliced-design` that means its hooks block `src/components/button.tsx` in a project that is not FSD. `marketplace add` has no scope flag; the project-scope install records the marketplace in the repository.

The install writes this to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/react-feature-kit" } }
  },
  "enabledPlugins": {
    "react-feature-workflow@vadimgaidai": true,
    "feature-sliced-design@vadimgaidai": true
  }
}
```

Commit it. Teammates then see the plugins as "not installed" and run the install lines once. [react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a repository set up this way.

## Requirements

- `node` for the hooks of all three plugins.
- One structure plugin per project. They disagree on what `src/` should look like.
- The Figma MCP server for `theme-sync` and `block-builder`.

## First run

```
/react-feature-workflow:review
```

On a branch with changes this needs nothing else: no spec, no `.planning/` folder. It reports against `CLAUDE.md`, `.claude/rules/` and the convention skills, and edits nothing.

```
/react-feature-workflow:spec add comments to articles
```

Read `.planning/comments/SPEC.md` and fix it, then run the next stages in order: `plan`, `implement`, `verify`, `review`, `refine`, a fresh session each. A request that is one block goes straight to `block-builder`; `spec` says so and stops. Prefix the request with `block:`, `layout:`, `feature:` or `change:` to set the shape yourself.

The convention skills and the structure hooks need no command. They apply while Claude writes.
