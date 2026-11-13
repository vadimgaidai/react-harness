---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

formatDecimal in src/lib/format-token-amount.ts should be able to append the token symbol, like `1.5 ETH`, when the caller has one. add that, and show the symbol next to the amounts in the activities list
