---
type: regex
pattern: 'status: capped[\s\S]*- 1 · [^\n]*verify failed[^\n]*AC-3[\s\S]*refine refused · cap of 1'
target:
  source: file
  path: .planning/token-symbol/LOOP.md
---
