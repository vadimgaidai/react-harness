# Rubric

What a component of this harness has to look like before it is called done. Structure and cost are measured with Claude Code's own tools, listed under [How it is measured](#how-it-is-measured); skills are written and iterated with the `skill-creator` skill, and this page adds only what is specific to the harness. `verify` is the reference: [SKILL.md](../plugins/react-harness/skills/verify/SKILL.md) and its [check script](../plugins/react-harness/skills/verify/scripts/check-verify.mjs).

## Pick the mechanism first

| The job | Goes into | Because |
|---|---|---|
| Has to happen every time, the same way | a script or a hook | a prompt is followed when the model weighs it that way |
| Needs judgement | a skill | a script cannot decide whether a criterion is met |
| Needs a clean context or produces a large payload | `context: fork` or a subagent | the session that wrote the code approves it, and a Figma payload fills the window |
| Has to be known in every session | the project's `CLAUDE.md` or `.claude/rules/` | a skill loads only when something triggers it |

A check the model is asked to do by reading its own output (ids unique, every id covered, a line cap) is a script. A count taken by a regex over the model's prose is a frontmatter field.

## A stage

- Names its input files. It reads them from disk and nothing from the conversation.
- Writes one file. Its frontmatter carries the state the next stage and the run log need: `stage`, `status`, and the ids or counts behind the status.
- Ends by running a check script on that file and fixing what the script names. The same script is the grader for the stage's eval.
- Knows nothing about how another stage works. It may name the next command in its reply.

## A skill

Written and revised through `skill-creator`, whose guide is the authority on form. What it asks for, as it applies here:

- `description` says what the skill does and when to use it; it is the only thing that triggers the skill. Each entry is cut at 1,536 characters and all installed skills share one listing budget.
- The body stays under 500 lines; detail moves to `references/` with a pointer that says when to read it.
- A constraint carries its reason. A rule in capitals is a sign the reason is missing.
- Examples for the calls that are easy to get wrong.
- Deterministic work is a file under `scripts/`, not a paragraph.

What the harness adds:

- `argument-hint` and `$ARGUMENTS` when the skill takes arguments.
- `context: fork` when it has to judge work it did not see being made.
- The goal and what done means come first, the output template last.
- A rule stated in one skill is not restated in another. The second skill names the first.

## An agent

- Exists for isolation: a payload that should not enter the session, or a judgement that should not see it. A job that needs neither is a skill.
- Its `tools` list covers everything its body tells it to do, `Skill` included when the body names a skill; `skills` preloads the ones it always needs.
- Does one job. Two modes are two agents.
- Cannot ask the user, so it says what is missing and stops.

## A hook

- Prevents a mistake that is expensive or cannot be undone, or does work nobody should spend tokens on.
- Fires only where the plugin's own work is happening: an `if` filter on the path, or a `hooks` entry in the frontmatter of the skill it guards.
- A hook that blocks an ordinary action in an ordinary session is removed.

## How it is measured

1. Structure: `claude plugin validate --strict <plugin>`, locally and in CI.
2. Context cost: `claude --plugin-dir <plugin> plugin details <name>` prints what each skill and agent adds to every session and what it costs when it fires.
3. Triggering: the description optimisation loop in `skill-creator`, over should-trigger and should-not-trigger prompts.
4. Behaviour: `skill-creator`'s loop while a skill is being written (test prompts, with the skill and without, results in its viewer), then the same case folders under `evals/` run by `claude plugin eval`. A stage's grader is its check script or a frontmatter field, never a regex over prose.
