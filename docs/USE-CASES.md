# Use cases

What you type, what lands on disk, where the kit stops. Commands come from `react-feature-workflow`; the last one needs a structure plugin.

## A review with no spec

```
/react-feature-workflow:review
```

On a branch somebody wrote by hand or in a plain chat. The scope is everything since the merge-base plus staged, unstaged and untracked work, or the range or paths you name. Each finding cites its rule: a line of `CLAUDE.md`, a `.claude/rules/` file, a section of a convention skill. Your typecheck, lint and tests run under Checks.

Where it stops: it writes no file without a `.planning/<name>/` folder and never edits code. Whether the change does what was asked is `verify`'s question and needs a spec.

## A feature with an API, stage by stage

Comments on articles: a backend contract, a list, a form, three UI states nobody wrote down.

```
/react-feature-workflow:spec add comments to articles
```

Claude asks for the Swagger URL and the endpoints as `GET /articles/{id}/comments`, never for shapes. It asks at most five questions, one per turn, with a recommended answer first. `.planning/comments/SPEC.md` appears:

```
R-1 WHEN the article page opens THE UI SHALL show the comments oldest first
R-3 IF the server answers 409 THEN THE UI SHALL show a conflict message and keep the text
…
AC-1 The comment list renders oldest first (R-1)
AC-3 A 409 answer shows a conflict message and keeps the typed text (R-3)
```

Plus UI states, permissions, failure scenarios and an `## Assumptions` list of what it guessed instead of asking. Read it and fix it. No module exists yet.

```
/react-feature-workflow:plan
```

Writes `contract.md`, the named endpoints cut from the OpenAPI file with every field marked required or optional, and `PLAN.md`: modules in build order, each with the `AC-` ids it serves, and a coverage table. The readiness check names anything the spec needs that the contract has no source for.

```
/react-feature-workflow:implement
/react-feature-workflow:verify
/react-feature-workflow:review
```

Fresh session each. `implement` builds in order and runs your typecheck. `verify` runs your tests, then answers each criterion:

```
- [x] AC-1 — executed — pnpm test comments: 1 passed
- [x] AC-2 — static — src/entities/comment/ui/comment-form.tsx:17 — submit disabled while isPending
- [ ] AC-3 — fail — nothing handles 409
- [?] AC-4 — unverifiable — manual — 1. go offline 2. submit 3. expect the retry
```

A fail sends you to `refine` before review. `review` reads the diff file by file against the convention skills and the rules in `CLAUDE.md`, and writes `REVIEW.md`. It never edits.

Where it stops: a field not in `contract.md` does not go into the types, however plausible. A behaviour the spec never named is a spec gap, routed back to `spec`, not a failure of the implementer.

## A change to a module that exists

```
/react-feature-workflow:spec change: the comment list paginates, 20 per page
```

The spec is a delta: added, modified, removed, plus `## Unchanged behaviour` listing what must keep working (oldest first, the empty state, no form for a signed-out reader). `verify` later checks that no hunk touches what that section protects.

## A small change in one command

```
/react-feature-workflow:autopilot show the token symbol next to amounts in the activity list
```

At most two questions, then a short `SPEC.md` and `PLAN.md` in the same formats as the full cycle, then `implement`, then `verify` and `review`, each in a subagent that starts from the files. A failed criterion goes to `refine` and back to `verify`, two rounds at most. The last message lists the criteria by verdict and the review's counts; `refine` applies the review findings when you ask.

Where it stops: more than five criteria, a new screen or module, a Figma design or a new dependency send it to `spec`; a gap in coverage or an open question that changes the build stops the run with the item named.

## A landing page from Figma

```
@react-feature-workflow:theme-sync https://figma.com/design/XX/landing
/react-feature-workflow:spec layout: build the landing from https://figma.com/design/XX/landing
/react-feature-workflow:plan
/react-feature-workflow:implement
```

`theme-sync` runs once per design and writes the light and dark palettes into your CSS, listing every variable with no token. The spec is light: page name, one node URL per section, which sections repeat, text. `implement` hands each section to `block-builder`, one subagent call per block, and assembles the page. Figma payloads stay inside the subagents.

Where it stops: a design value with no token is reported as `NO MATCH`, never rounded to the nearest colour.

## One block, no workflow

```
@react-feature-workflow:block-builder https://figma.com/design/XX/landing?node-id=42-15 into src/widgets/hero
```

Builds the block from shadcn primitives and semantic tokens, downloads the exported assets into the repository, reports what had no token. `spec` on a request this small gives the same answer and writes nothing.

## A bug

```
@react-feature-workflow:bug-fixer the comment form submits twice on slow connections
```

Reproduces it, names the `file:line` cause, fixes it with the fewest files. Cannot reproduce it: says so. No refactoring on the way.

## A file in the wrong place

With `feature-sliced-design`, Claude writes `src/utils/format.ts`. The hook refuses before the file exists and names `src/shared/lib/`. Same for `UserCard.tsx`, a `@/shared/ui` barrel import, an entity importing a feature, a domain interface inside a `ui/*.tsx`.

With `feature-folders`, only new files are checked. Editing `src/pages/settings/preferences.tsx` from three years ago passes. A new `src/utils/format-date.ts` is refused and pointed to `src/lib/`. Whether a new provider is local or global is the skill's table, not a hook; a wrong call there shows up in `review`.
