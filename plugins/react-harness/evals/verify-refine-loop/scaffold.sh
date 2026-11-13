#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/../_fixture/base.sh"

mkdir -p .planning/token-symbol

cat > src/lib/format-token-amount.ts <<'EOF'
interface IFormatDecimalOptions {
  maxDecimals: number
  symbol?: string
}

export const formatDecimal = (value: number, { maxDecimals, symbol }: IFormatDecimalOptions): string => {
  const formatted = new Intl.NumberFormat("en-US", { maximumFractionDigits: maxDecimals }).format(value)

  if (!symbol) {
    return formatted
  }

  return `${formatted} ${symbol}`
}
EOF

sed -i.bak 's/formatDecimal(item.amount, AMOUNT_DECIMALS)/formatDecimal(item.amount, { maxDecimals: AMOUNT_DECIMALS })/' src/pages/portfolio/components/activities-list/index.tsx
rm src/pages/portfolio/components/activities-list/index.tsx.bak

cat > .planning/token-symbol/LOOP.md <<'EOF'
---
status: running
iteration: 0
max_iterations: 4
---

# Loop: token-symbol
EOF

cat > .planning/token-symbol/SPEC.md <<'EOF'
# SPEC: token-symbol
**Shape:** change

## Request
formatDecimal should append the token symbol when the caller has one, and the activities list shows it.

## Goal
Each amount in the activities list is shown with its token symbol, like `1.5 ETH`.

## Behaviour
R-1 WHEN an amount is formatted with a token symbol THE UI SHALL show the amount, a space and the symbol.
R-2 WHEN an amount is formatted without a symbol THE UI SHALL show the amount alone.
R-3 WHEN the activities list shows a transaction THE UI SHALL show its amount followed by that transaction's symbol.

## Unchanged behaviour
Rounding to at most four decimals, kind labels and the sync banner stay as before.

## Data sources
none

## Acceptance criteria
AC-1 an amount of 1.5 with the symbol ETH reads `1.5 ETH` (R-1)
AC-2 an amount of 1.5 with no symbol reads `1.5` (R-2)
AC-3 every row of the activities list shows its amount followed by its own symbol (R-3)

## Assumptions
- Transactions already carry a symbol.

## Open questions
none
EOF

cat > .planning/token-symbol/PLAN.md <<'EOF'
# PLAN: token-symbol

**Spec:** `.planning/token-symbol/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules
| # | Path | Role | Depends on | Serves |
|---|---|---|---|---|
| 1 | src/lib/format-token-amount.ts | formatter | — | AC-1, AC-2 |
| 2 | src/pages/portfolio/components/activities-list | list rows | 1 | AC-3 |

## Conventions to follow
The existing activities list.

## Contract
none

## Per module
### `src/lib/format-token-amount.ts`
- **Files**: edited; options object `{ maxDecimals, symbol? }`
### `src/pages/portfolio/components/activities-list`
- **Files**: `index.tsx` passes `item.symbol`

## Decisions
Options object instead of a third parameter (code-shape).

## Coverage
| AC | Modules | Evidence `verify` should expect |
|---|---|---|
| AC-1 | 1 | static: formatter appends the symbol |
| AC-2 | 1 | static: no symbol returns the amount |
| AC-3 | 2 | static: the row passes item.symbol |
EOF

