---
type: regex
pattern: 'status: finished[\s\S]*- 1 · [^\n]*verify failed[^\n]*AC-3[\s\S]*· refine\s[\s\S]*- 2 · [^\n]*verify (?:ready|checks-skipped)[\s\S]*· review [\s\S]*finished'
target:
  source: file
  path: .planning/token-symbol/LOOP.md
---
