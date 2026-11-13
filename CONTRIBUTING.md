# Contributing

## Dev loop

```bash
claude --plugin-dir ./plugins/react-feature-workflow
/reload-plugins        # after editing a skill or hook
```

## Checks

```bash
claude plugin validate --strict .
for p in plugins/*/; do claude plugin validate --strict "$p"; done
```

CI runs the same two commands. What is and is not measured: [docs/DESIGN.md](./docs/DESIGN.md#how-the-kit-is-measured).

What a skill, an agent, a hook and a stage have to look like: [docs/RUBRIC.md](./docs/RUBRIC.md). Skills are written and measured with Claude Code's own tools, listed there.

## Releasing

Bump the version or nothing ships. `claude plugin update` compares `version` with the installed copy and skips the update when they match. The version lives in `plugins/<name>/.claude-plugin/plugin.json` and in `.claude-plugin/marketplace.json` and has to match.

## Layout

```
.claude-plugin/marketplace.json   plugins, versions, descriptions
plugins/<name>/
  .claude-plugin/plugin.json      name and version must match the marketplace entry
  skills/<skill>/SKILL.md         frontmatter name must match the directory
  skills/<skill>/references/      worked shapes; each file is linked from its SKILL.md
  agents/*.md                     frontmatter: name and description
  hooks/hooks.json                commands point into hooks/scripts/
docs/                             getting started, use cases, design, rubric
```
