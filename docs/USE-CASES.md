# Use cases

What you type, what lands on disk, where the harness stops. The first two need no command. The rest come from `react-harness`; the last needs a structure plugin.

## A crypto dashboard from one sentence

```
build a crypto wallet portfolio page: total value with 24h change, a wallet card with a network switch, an allocation pie, a value chart with ranges, and tokens / transactions / staking tabs kept in the URL; fake API, every region with its own loading, empty and error state
```

No command. At session start a hook printed which convention skills to call for a component, a query, a mutation and a route; Claude calls them before the first edit, and the structure skill answers what is a feature module and what is global.

Without the harness, everything about the page lands in one folder, every resource shares three API files, and a `shared.tsx` collects whatever did not fit:

```
src/
├── api/                 portfolio.ts · queries.ts · types.ts
├── components/portfolio/
│   ├── Allocation.tsx · Hero.tsx · StakingTab.tsx · TokensTab.tsx
│   ├── TransactionsTab.tsx · WalletCard.tsx
│   └── shared.tsx       Panel, TokenMark, PctChange, DataRegion, Segmented
├── pages/PortfolioPage.tsx
└── lib/                 format.ts · tokens.ts · utils.ts
```

With the harness and `feature-folders`, each domain area is a module with one barrel, each backend resource is an API folder, and the page only composes:

```
src/
├── api/
│   ├── portfolio/     portfolio.api.ts · portfolio.queries.ts · types.ts · index.ts
│   ├── staking/       staking.api.ts · staking.queries.ts · staking.mutations.ts · types.ts · index.ts
│   ├── transactions/  transactions.api.ts · transactions.queries.ts · types.ts · index.ts
│   └── wallet/        wallet.api.ts · wallet.queries.ts · types.ts · index.ts
├── features/
│   ├── holdings/      components/ · index.ts
│   ├── overview/      components/ (header, value chart, allocation chart) · index.ts
│   ├── staking/       components/ (panel, table, claim button) · index.ts
│   ├── transactions/  components/ (panel, table, type badge, pagination, details) · index.ts
│   └── wallet/        components/ (card, address, network switch) · index.ts
├── pages/portfolio/   portfolio-page.tsx · portfolio-tabs.tsx
├── components/        query-boundary · region-error · empty-state · table-skeleton · trend-text
├── hooks/             use-portfolio-params.ts
├── config/            paths · locales · portfolio params
├── app/               app.tsx · router.tsx
└── lib/               query-client · i18n · format · api-error
```

Inside the files the difference is the same. Without the harness, one tab holds its query, its loading, empty and error branches, a summary block, the table, the rows and the claim button with its toast, and borrows a skeleton from a sibling tab:

```tsx
// src/components/portfolio/StakingTab.tsx
import { DataRegion, TokenMark } from './shared'
import { TableSkeleton } from './TokensTab'

export function StakingTab({ network }: { network: Network }) {
  const query = useStaking(network)
  return (
    <DataRegion query={query} isEmpty={(d) => d.positions.length === 0} empty={…} skeleton={…}>
      {(data) => (<>{/* summary, table, rows, claim button: ~110 lines */}</>)}
    </DataRegion>
  )
}
```

With the harness, one boundary owns loading and failure, the table only renders data, and the action's side effects live in its mutation:

```tsx
// src/features/staking/components/staking-panel.tsx
export default function StakingPanel() {
  const { t } = useTranslation()
  const [{ network }] = usePortfolioParams()

  return (
    <QueryBoundary fallback={<TableSkeleton rows={3} />} errorTitle={t("staking.errors.load")} resetKeys={[network]}>
      <StakingTable />
    </QueryBoundary>
  )
}
```

```tsx
// src/features/staking/components/staking-table.tsx
export const StakingTable = () => {
  const { t } = useTranslation()
  const [{ network }] = usePortfolioParams()
  const { data: overview } = useSuspenseQuery(stakingQueries.overview(network))

  if (overview.positions.length === 0) {
    return <EmptyState icon={LandmarkIcon} title={t("staking.empty.title")} description={t("staking.empty.description")} />
  }

  return …
}
```

```ts
// src/api/staking/staking.mutations.ts
export const useClaimRewardsMutation = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: stakingApi.claimRewards,
    onSuccess: (overview, { network }) => {
      queryClient.setQueryData(stakingKeys.overview(network), overview)
      toast.success(i18n.t("staking.claim.success"))
      return queryClient.invalidateQueries({ queryKey: portfolioKeys.byNetwork(network) })
    },
    onError: () => {
      toast.error(i18n.t("staking.claim.error"))
    },
  })
}
```

The active tab and the network live in the URL through `usePortfolioParams`, so a shared link opens the same tab. Types are `IStakingPosition` and `TNetwork`; every label goes through `t()`. Before reporting done, Claude opens the page in the browser at desktop and 375 px, switches the tab and forces a claim failure.

Where it stops: the hook blocks a new `src/components/StakingTab.tsx` or a type written into a `.tsx`, and nothing else. A rule the model skipped on one line is a `review` finding, not a blocked write.

## A file in the wrong place

With `feature-folders`, Claude writes `src/utils/format.ts`. The hook refuses before the file exists and names `src/lib/`. Same for `UserCard.tsx`, a `@/components/ui` barrel import, a zod schema inside a page component, a feature with its own `api/` folder. Only new files are checked for placement and naming, so editing `src/pages/settings/preferences.tsx` from three years ago passes.

With `feature-sliced-design`, every write is checked: a file outside the six layers, an entity importing a feature, `useMutation` inside an entity, a domain interface inside a `ui/*.tsx`.

## A review with no spec

```
/react-harness:review
```

On a branch somebody wrote by hand or in a plain chat. The scope is everything since the merge-base plus staged, unstaged and untracked work, or the range or paths you name. Each finding cites its rule: a line of `CLAUDE.md`, a `.claude/rules/` file, a section of a convention skill. Your typecheck, lint and tests run under Checks.

Where it stops: it writes no file without a `.planning/<name>/` folder and never edits code. Whether the change does what was asked is `verify`'s question and needs a spec.

## A small change through the automatic loop

```
/react-harness:autopilot show the token symbol next to amounts in the activity list
```

At most two questions, then `.planning/token-symbol/SPEC.md` with two to five criteria and `PLAN.md` with the module it touches, then `implement` in the same session, then the loop. `LOOP.md` is written first:

```markdown
---
status: running
iteration: 0
max_iterations: 4
---
```

From here a hook on every `Skill`, `Write` and `Edit` call decides what runs. `verify` forks, reads the spec and the diff, writes `VERIFY.md`. One criterion failed, so the only stage the hook allows is `refine`; it fixes the open item in this session, and the code edit makes `verify` the next stage again. The second `verify` passes, so the hook allows `review`, which forks and writes `REVIEW.md`. The turn cannot end while a stage is left. `LOOP.md` keeps the history:

```
- 14:02 verify — failed — AC-2 (round 1)
- 14:04 refine — AC-2
- 14:06 verify — ready (round 2)
- 14:07 review — 1 style finding, 0 engineering remarks
```

The last message lists the criteria by verdict and the review's counts, and ends with "Say `refine` to apply the review findings". That reply reopens the loop for one more round.

Where it stops: more than five criteria, a new screen or module, a Figma design or a new dependency send it to `spec`. The same criteria failing two rounds in a row ends the loop as `stuck`; the fourth round ends it as `capped`; a red typecheck the model cannot settle ends it as `stopped`, with the reason under the log.

## A feature with an API, stage by stage

Comments on articles: a backend contract, a list, a form, three UI states nobody wrote down. Every stage is a command you start; run them one at a time, in any model you choose per stage.

```
/react-harness:spec add comments to articles
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
/react-harness:plan
```

Writes `contract.md`, the named endpoints cut from the OpenAPI file with every field marked required or optional, and `PLAN.md`: modules in build order, each with the `AC-` ids it serves, and a coverage table. The readiness check names anything the spec needs that the contract has no source for.

```
/react-harness:implement
/react-harness:verify
/react-harness:review
```

`implement` builds in order with the same convention skills as a plain request and runs your typecheck. `verify` forks, runs your tests, then answers each criterion:

```
- [x] AC-1 — executed — pnpm test comments: 1 passed
- [x] AC-2 — static — src/features/comments/components/comment-form.tsx:17 — submit disabled while isPending
- [ ] AC-3 — fail — nothing handles 409
- [?] AC-4 — unverifiable — manual — 1. go offline 2. submit 3. expect the retry
```

A fail sends you to `refine` before review. `review` forks, reads the diff file by file against the convention skills and the rules in `CLAUDE.md`, and writes `REVIEW.md`. It never edits.

Where it stops: a field not in `contract.md` does not go into the types, however plausible. A behaviour the spec never named is a spec gap, routed back to `spec`, not a failure of the implementer.

## A change to a module that exists

```
/react-harness:spec change: the comment list paginates, 20 per page
```

The spec is a delta: added, modified, removed, plus `## Unchanged behaviour` listing what must keep working (oldest first, the empty state, no form for a signed-out reader). `verify` later checks that no hunk touches what that section protects.

## A landing page from Figma

```
@react-harness:theme-sync https://figma.com/design/XX/landing
/react-harness:spec layout: build the landing from https://figma.com/design/XX/landing
/react-harness:plan
/react-harness:implement
```

`theme-sync` runs once per design and writes the light and dark palettes into your CSS, listing every variable with no token. The spec is light: page name, one node URL per section, which sections repeat, text. `implement` hands each section to `block-builder`, one subagent call per block, and assembles the page. Figma payloads stay inside the subagents.

Where it stops: a design value with no token is reported as `NO MATCH`, never rounded to the nearest colour.

## One block, no workflow

```
@react-harness:block-builder https://figma.com/design/XX/landing?node-id=42-15 into src/features/hero
```

Builds the block from shadcn primitives and semantic tokens, downloads the exported assets into the repository, reports what had no token. `spec` on a request this small gives the same answer and writes nothing.

## A bug

```
@react-harness:bug-fixer the comment form submits twice on slow connections
```

Reproduces it, names the `file:line` cause, fixes it with the fewest files under the same convention skills. Cannot reproduce it: says so. No refactoring on the way.
