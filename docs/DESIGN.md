# Design

The decisions behind the harness, with what each one changes in the code.

## Structure first, design on top

The harness makes Claude write one architecture and one code style: a module per domain area, an API folder per backend resource, one way to load data, the house rules for plain code. A structure plugin holds the folders and blocks a misplaced file. Nine convention skills hold the code rules and load while Claude writes the matching layer. A plain request is the default mode and the one the harness is measured in.

The look is left to the model and to design plugins installed next to the harness. One rule guards it: a built or changed screen is opened in the browser at desktop and 375 px before it is called done. A separate check stage and a Stop hook were tried and dropped: both cost on every turn for what they caught.

## Three modes, chosen by the user

- **A plain request.** The route hook and the structure hook work on every session. Nothing to type.
- **Manual stages.** For a large task: the user reads `SPEC.md` before any code, checks `PLAN.md` before any module, and may plan in one model and implement in another. More time and tokens, paid knowingly.
- **`autopilot`.** For work nobody watches: a small change, or an agent in the background. The stages run in one turn under a hook.

The model never starts a stage on its own: `spec`, `plan` and `autopilot` have `disable-model-invocation`. A model that decided the user wanted a spec would spend the user's tokens on ceremony nobody asked for. In an unattended run `autopilot` asks nothing and records what it decided under `## Assumptions`; a question with nobody to answer it ends the run.

## What the rules change, file by file

Each pair below is the same request without the harness and with it. The "without" side is what a capable model writes on its own; nothing in it is wrong, and none of it is consistent from one session to the next.

### Where files go

Without: the page's files sit in one folder named after the page, every resource shares three API files, and a `shared.tsx` holds whatever did not fit.

```
src/api/            portfolio.ts · queries.ts · types.ts
src/components/portfolio/
                    StakingTab.tsx · TokensTab.tsx · WalletCard.tsx · shared.tsx
src/pages/PortfolioPage.tsx
```

With: a module per domain area from its first file, an API folder per backend resource, and the page only composes. The structure hook refuses anything else before it is written.

```
src/api/staking/            staking.api.ts · staking.queries.ts · staking.mutations.ts · types.ts · index.ts
src/features/staking/       components/ (panel, table, claim button) · index.ts
src/pages/portfolio/        portfolio-page.tsx · portfolio-tabs.tsx
```

### The API layer

Without: a hook per call with the key written by hand where it is used, so a mutation that wants to invalidate the list has to guess the same array.

```ts
export const useStaking = (network: Network) =>
  useQuery({ queryKey: ['staking', network], queryFn: () => getStaking(network) })

queryClient.invalidateQueries({ queryKey: ['staking', network] })
```

With: one file per role. `staking.api.ts` holds the HTTP calls and nothing else. `staking.queries.ts` holds the key factory and `queryOptions`, so the component, the loader and the mutation all use one key and one fetcher.

```ts
export const stakingKeys = {
  all: () => ["staking"] as const,
  overview: (network: TNetwork) => [...stakingKeys.all(), "overview", network] as const,
}
export const stakingQueries = {
  overview: (network: TNetwork) =>
    queryOptions({ queryKey: stakingKeys.overview(network), queryFn: () => stakingApi.overview(network) }),
}
```

### Loading data

Without: every component handles its own `isPending`, `isError` and empty branches, or a home-made render-prop helper does, and `data` is typed as possibly undefined everywhere.

```tsx
const query = useStaking(network)
if (query.isPending) return <Skeleton />
if (query.isError) return <ErrorBox error={query.error} />
if (query.data.positions.length === 0) return <Empty />
```

With: one `QueryBoundary` per region owns loading and the failed first load. The component reads with `useSuspenseQuery`, so `data` is present, and renders data or its own empty branch.

```tsx
<QueryBoundary fallback={<TableSkeleton rows={3} />} errorTitle={t("staking.errors.load")}>
  <StakingTable />
</QueryBoundary>

const { data } = useSuspenseQuery(stakingQueries.overview(network))
if (data.positions.length === 0) {
  return <EmptyState title={t("staking.empty.title")} />
}
```

### Components

Without: one tab component holds the query, the states, a summary block, the table, a row component and the claim button with its toast, about 110 lines, and imports a skeleton from a sibling tab.

With: a panel that owns the boundary, a table that renders data, a button that calls the mutation. One exported component per file, props typed on the parameter as `IStakingTableProps`, never `FC`.

### Mutations and errors

Without: the button calls `mutate` and toasts in its own `onSuccess`; a second caller adds a `try/catch` with a second toast; the cache is refreshed with `refetch()` or not at all.

With: the mutation hook owns its side effects, and a failure has one owner.

```ts
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

The caller passes a per-call `onSuccess` for its follow-up and nothing else.

### URL state

Without: the active tab and the network are read from the URL once and copied into `useState`, so Back changes the address bar and leaves the screen as it was.

```tsx
const [tab, setTab] = useState(searchParams.get('tab') ?? 'tokens')
```

With: one hook per screen parses the search params through a schema with a default per field and returns `[params, setParams]`, where the setter takes a patch. The query key is built from the parsed values, so a shared link opens the same data.

```ts
const [{ tab, network }, setParams] = usePortfolioParams()
setParams({ network: "base" })
```

### Types

Without: an interface written by hand next to the fetcher, a cast where a string comes in, an `enum` for a fixed set.

```ts
const network = searchParams.get('network') as Network
enum Network { Ethereum = 'ethereum', Arbitrum = 'arbitrum' }
```

With: types come from the contract or from inference, a fixed set is an `as const` list with a derived union, and outside input is narrowed by a guard once. Object shapes are `interface I…`, unions `type T…`.

```ts
export const NETWORKS = ["ethereum", "arbitrum", "base"] as const
export type TNetwork = (typeof NETWORKS)[number]
export const isNetwork = (value: unknown): value is TNetwork => NETWORKS.some((network) => network === value)
```

### Forms

Without: `useState` per field, checks in `onChange`, a `fetch` in the submit handler, an interface for the values written by hand.

With: the schema in its own file and `z.infer` as the form type; `useForm` with `zodResolver` and a default for every field; every field through `Controller` inside shadcn's `Field`; the submit target is the module's mutation hook; a server-side field error goes to `setError`. Never `useActionState` or `<form action>`.

### Plain code

Without: a third positional parameter, a boolean flag, `if (x) return y` on one line, a nested ternary, a comment explaining the line below it.

```ts
const formatAmount = (value: number, decimals: number, compact: boolean) => …
formatAmount(total, 2, true)
```

With: at most two parameters, then a typed options object; guard clauses first and every `return` in a braced block; a ternary chooses between values, never between behaviours; no comments except `// TODO:` and `// !`.

```ts
const formatAmount = (value: number, { decimals, compact }: IFormatAmountOptions) => …
formatAmount(total, { decimals: 2, compact: true })
```

### UI

Without: a `div` with `h-4 w-4 text-gray-500 ml-2 space-x-2 dark:text-gray-400`, a hand-rolled empty state, a label as a string literal.

With: the installed shadcn primitive (`Empty`, `Spinner`, `Skeleton`, `Alert`), `size-4 text-muted-foreground ms-2 gap-2`, no `dark:` in a component, every visible string through `t("key")`. Logical spacing means a right-to-left language mirrors the layout with no second set of classes.

### Tests

Without: `useQuery` mocked to return data, elements found by test id, a sleep before the assertion.

With: a real `QueryClient` with the network mocked at the boundary (MSW), elements found by role and accessible name, `findBy*` for async UI, and pending, failure and retry each with their own test.

A whole page built this way next to the same page built without the harness: [USE-CASES.md](./USE-CASES.md#a-crypto-dashboard-from-one-sentence). Every pattern lives in one skill under `plugins/react-harness/skills/`, with its edge cases in that skill's `references/`.

## Spec before plan

`SPEC.md` is the first file a human reads: what the user sees, as rules with ids, and acceptance criteria that cite them. No file paths, components or libraries, because a spec written as pseudo-code is the program written twice.

`spec` hunts gaps by a fixed taxonomy, asks five questions at most, one per turn with a recommended answer, and records the rest as assumptions. `plan` cites the spec and never copies it: each module names the criteria it serves, a coverage table maps every criterion back, and the hand-off is refused while a criterion has no module.

## Stages are files

Each stage writes a file and the next one reads it from disk, never from the conversation, so the stages can run in one session or one per session with the same result. `implement` and `refine` run in the main session and never fan out, since the convention skills are loaded there.

A session that reviews code it just wrote approves it, so `verify` and `review` fork their own context: each starts from the files and the diff, with nothing about the build. `autopilot` runs every stage in one turn and still forks those two.

Four shapes, decided before anything else: a block goes straight to `block-builder`, a layout gets a light spec, a feature the full one, a change a delta with an unchanged-behaviour section.

## Two things outrank the plan

`contract.md` for shapes: cut from the OpenAPI file by a script, every `$ref` inlined, every field marked required or optional. A field absent from it does not exist. `SPEC.md` for behaviour. When the plan disagrees with either, `implement` follows the authority and reports the deviation.

## What stays out of the context window

### Scripts

| Script | Plugin | Replaces | What enters the window instead |
|---|---|---|---|
| `contract-slice.mjs` | react-harness, `api-contract` | reading the whole OpenAPI file | `contract.md`: the endpoints the spec names |
| `sibling-outline.sh` | react-harness, `implement` | reading every file of the mirrored module | a map: folder shape, barrel, exported signatures at `path:line`; files with the same role as what is being written are then read whole |
| `reviewing-sections.mjs` | react-harness, `review` | the model reading nine skills to find their review questions | the nine `references/reviewing.md` files, printed into the prompt once at invocation |
| `check-verify.mjs` | react-harness, `verify` | the model re-reading `VERIFY.md` for a missing verdict | one line per defect; the same script grades the stage's eval |
| `scaffold.sh` | both structure plugins | generating directories, barrels and empty model files | one shell call per module |
| `structure-check.sh` | both structure plugins | reading every module to check its barrel | one line per defect over the changed files, under `review`'s Checks |

### Hooks

| Hook | Plugin | Does |
|---|---|---|
| `session-skills` | react-harness | on `SessionStart` and `SubagentStart`, names the convention skills to call by what the work touches; carries no rules itself |
| `loop-guard` | react-harness | while a `LOOP.md` is `running`: allows only the next stage, counts rounds, refuses a stage past `max_iterations`, ends the loop as `stuck` on repeated failure, takes only `status: stopped` from the model, forces a new `verify` after a code edit, keeps the turn open while a stage is left |
| `format-on-edit` | react-harness | runs the project's Prettier on every file a Write or Edit touched; shell writes are left to the project's pre-commit hook |
| `structure-validator` | one per structure plugin | refuses a file on the wrong layer or bucket, a wrong filename, a barrel import, a domain type or schema in a UI file, and in FSD an upward or sideways import |

### Subagents

`block-builder` and `theme-sync` fetch the Figma payload, write the files or the token map, and return a short report. `bug-fixer` reproduces and fixes in its own window. The main session never receives the JSON.

## Skills carry code rules, hooks only route to them

The hooks above are the only hooks. Code rules live in the skills; the model applies them while writing and `review` applies them while reading. The harness ships no lint config and no scanner: a regex that flags a comment or a third argument judges code by its surface, and a second ESLint config argues with what the project already decided. The project's own typecheck, lint and tests run under `review`'s Checks.

## The loop is a state machine

`autopilot`'s verify → refine → review loop lives in `loop-guard`, not in the prompt. The next stage is computed from `VERIFY.md`, `REVIEW.md` and `LOOP.md`; any other stage is refused with the one to run. Four exits: `finished` when no stage is left, `stuck` when the same criteria fail two `verify` rounds in a row, `capped` at `max_iterations` (4), `stopped` when the model hands the run to the human. Repair loops gain most in the first three or four rounds; sources in `.planning/harness-rework/LOOP-RESEARCH.md`.

## Verify and review are different questions

`verify` asks whether the change satisfies the spec. Each criterion gets a verdict and an evidence tier: `executed` when a command ran and its output is quoted, `static` when a `file:line` implements it, `manual` when only a human with a browser can settle it. It runs the project's tests and writes none.

`review` asks whether the change follows the rules and whether its decisions were necessary. It reads the diff file by file. A style violation is reported with the rule and the line; an engineering remark carries its argument: the helper that already exists, the work repeated per element. A single caller, an intermediate variable, a long file or a `try/catch` is never a finding on its own.

Neither edits. `refine` takes both files, checks each item against the code as it is, applies one at a time, declines with evidence. Correctness bugs, security and generic simplification belong to `/code-review`, `/security-review` and `/simplify`.

## One structure plugin per architecture

`feature-sliced-design` assumes all of `src/` is FSD and blocks any write outside its layers. `feature-folders` assumes nothing about the old tree: placement and naming block new files only, and the one content rule (a domain type, a constant, a schema, a hook or an HTTP call in a UI file) applies to old files and new. They disagree on what `src/` should look like. Install the one that matches.

## How the harness is measured

Structure on every commit: `claude plugin validate --strict` over the marketplace and each plugin, locally and in CI.

Whether the code follows the house rules: the cases under `plugins/react-harness/evals/`, run by `claude plugin eval` with the plugin and without. `gen-*` cases grade one rule in the written code and whether its skill was called; `review-*` cases grade that `review` reports a planted violation and stays quiet on a correct file; `impl-*`, `autopilot-*`, `verify-refine-loop` and `loop-cap` grade that a stage or the loop did what its file says; `outcome-*` cases are read by hand against a checklist.

Whether a whole project comes out in the structure: one task run headless from an empty folder, once without the harness, once with the two plugins on a plain request, once through the stage commands. The trees and the files are read by hand.
