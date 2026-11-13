---
max_turns: 50
timeout_seconds: 900
tags: [autopilot]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

/react-harness:autopilot formatDecimal in src/lib/format-token-amount.ts should be able to append the token symbol, like `1.5 ETH`, when the caller has one. add that, and show the symbol next to the amounts in the activities list. call the work token-symbol
