---
type: regex
pattern: 'if\s*\(.*\)[ \t]*return\b'
match: 'not_contains'
target:
  source: file
  path: src/pages/portfolio/hooks/use-get-activities.ts
---
