# Design

The decisions behind the kit, one section each.

## Spec before plan

The first file a human reads is `SPEC.md`: what the user sees, as rules with ids, and acceptance criteria that cite those rules. No file paths, no components, no libraries. A spec that reads as pseudo-code is the program written twice, and a gate on implementation is not a gate on behaviour.

`spec` finds gaps by taxonomy, nine categories rated clear, partial or missing, and asks five questions at most. Everything else becomes a recorded assumption. A guess on disk is cheaper to reverse than a sixth question.

`plan` cites the spec and never copies it. Each module names the criteria it serves, a coverage table maps every criterion back, and the hand-off is refused while a criterion has no module. Behaviour lives in one file, so a changed mind has one place to change.

## Stages are files

Each stage writes a file and the next one reads it in a fresh session. The planning chat adds nothing to the build. A session that reviews code it just wrote approves it.

`verify` and `review` fork their own context: each starts from the files and the diff, with nothing about the build.

Four shapes, decided before anything else: a block goes straight to `block-builder`, a layout gets a light spec, a feature the full one, a change a delta with an unchanged-behaviour section.

## Two things outrank the plan

`contract.md` for shapes. It is cut from the OpenAPI file by a script, with every `$ref` inlined and every field marked required or optional. A field absent from it does not exist. `SPEC.md` for behaviour. When the plan's prose disagrees with either, `implement` follows the authority and reports the deviation.

## What stays out of the context window

Most of the kit's tokens go to reading, not writing. Every mechanism below replaces something the model would otherwise read whole, generate by hand or paste into the session.

### Scripts

| Script | Plugin | Replaces | What enters the window instead |
|---|---|---|---|
| `contract-slice.mjs` | react-feature-workflow, `api-contract` | reading the whole OpenAPI file, tens of thousands of tokens for a mid-sized API | `contract.md`: the endpoints the spec names, every `$ref` inlined, every field marked required or optional |
| `sibling-outline.sh` | react-feature-workflow, `implement` | reading files of the mirrored module that play no role in the build | a map: folder shape, barrel, short files whole, exported signatures of long files at `path:line`, key factories, external imports. The files with the same role as what is being written are then read whole |
| `scaffold.sh` | both structure plugins | generating directories, barrels and empty model files per module | one shell call per module; generation spends tokens only on the code that differs |
| `structure-check.sh` | both structure plugins | reading every module to see whether its barrel is complete | one line per defect over the changed files, under `review`'s Checks |

### Hooks

| Hook | Plugin | Refuses | Saves |
|---|---|---|---|
| `session-skills` | react-feature-workflow | nothing; on `SessionStart` and `SubagentStart` names the convention skills to call by what the work touches | nothing; it is the route from a coding request to the house rules |
| `loop-guard` | react-feature-workflow | while a `LOOP.md` is `running`: any stage but the next one, a `verify` or `refine` past `max_iterations`, a second `verify` failing on the same criteria, which ends the loop as `stuck`, an edit of `LOOP.md` other than `status: stopped`, and the end of a turn while a stage is left; a code edit after `verify` makes `verify` the next stage | rounds the model would count in its head, and the history `verify` overwrites: a line per stage call in `LOOP.md` |
| `format-on-edit` | react-feature-workflow | nothing; runs Prettier on the file a Write or Edit touched; shell writes are left to the project's pre-commit hook | output tokens on formatting, in every stage |
| `structure-validator` | structure plugins, one each | a file on the wrong layer or bucket, a wrong filename, a barrel import, a domain type or a schema in a UI file, and in FSD an import that goes sideways or up | the review round that would find it, and the rewrite after |

### Subagents

`block-builder` and `theme-sync` fetch the Figma payload, write the files or the token map, and return a short report. `bug-fixer` reproduces and fixes in its own window. The main session receives components and a few lines, never the JSON.

### Stages as files

`SPEC.md`, `PLAN.md`, `contract.md`, `DESIGN.md`, `VERIFY.md` and `REVIEW.md` are what the next stage reads; the conversation that produced them is not. `implement` starts with two capped files instead of a planning chat, `review` reads the diff file by file instead of a session's worth of edits.

## Skills carry code rules, hooks only route to them

The hooks above and the structure plugins' placement hooks are the only hooks. Code rules live in the convention skills: no comments except `TODO:` and `!`, two parameters, guard clauses, no nested ternaries, collections judged by repeated work, error ownership, type discipline. The model applies them while writing and `review` applies them while reading.

The kit ships no lint config and no scanner. A regex that flags a comment, a third argument or a `useMemo` judges code by its surface. A second ESLint config argues with what the project already decided. The project's own typecheck, lint and tests run under `review`'s Checks.

## The loop is a state machine

`autopilot`'s verify → refine → review loop lives in `loop-guard`, not in the prompt. The next stage is computed from `VERIFY.md`, `REVIEW.md` and `LOOP.md`; any other stage is refused with the one to run. The model does the work inside a stage and never picks the order.

Four exits: `finished` when no stage is left, `stuck` when the same criteria fail two `verify` rounds in a row, `capped` at `max_iterations` (4), `stopped` when the model hands the run to the human. Most of what repair loops gain comes in the first three or four rounds, and a round that changes nothing changes nothing the next time either; sources in `.planning/harness-rework/LOOP-RESEARCH.md`.

## Verify and review are different questions

`verify` asks whether the change satisfies the spec. Each criterion gets a verdict and an evidence tier: `executed` when a command ran and its output is quoted, `static` when a `file:line` implements it, `manual` when only a human with a browser can settle it. It runs the project's tests and writes none: a verifier that writes the test it then passes grades its own work.

`review` asks whether the change follows the rules and whether its decisions were necessary. It reads the diff file by file, asks every question of a file once, and opens more only for a specific question. A style violation is reported with the rule and the line. An engineering remark carries its argument: the helper that already exists, the data that already determines the value, the work repeated per element. Both name the rule they cite, by skill and section. A single caller, an intermediate variable, a long file, a `try/catch`, an optional chain or a fallback is never a finding on its own.

Neither edits. `refine` takes both files in, checks each item against the code as it is, applies one at a time, declines with evidence. Correctness bugs, security and generic simplification belong to `/code-review`, `/security-review` and `/simplify`.

## One structure plugin per architecture

`feature-sliced-design` assumes all of `src/` is FSD and blocks any write outside its layers. `feature-folders` assumes nothing about the old tree: placement and naming block new files only, so years of existing structure are left alone, and the one content rule (a domain type, a constant, a schema, a hook or an HTTP call in a UI file) applies to old files and new. They disagree on what `src/` should look like. Install the one that matches.

## How the kit is measured

Structure on every commit: `claude plugin validate --strict` over the marketplace and each plugin, locally and in CI.

Whether the code follows the house rules: the `gen-*` and `review-*` cases under `plugins/react-feature-workflow/evals/`, run by `claude plugin eval` with the plugin and without. A case grades the rule in the written code and whether the convention skill was called.
