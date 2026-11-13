---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

debounce the search value in src/pages/portfolio/hooks/use-search.ts by 300ms so the list doesn't refetch on every keystroke. return both the raw and the debounced value
