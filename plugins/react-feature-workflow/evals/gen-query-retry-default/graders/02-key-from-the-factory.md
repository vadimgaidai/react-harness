---
type: regex
pattern: 'queryKey\s*:\s*\['
match: 'not_contains'
target:
  source: file
  path: src/api/activity/queries.ts
---
