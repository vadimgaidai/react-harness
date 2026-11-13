---
type: regex
pattern: 'formatDecimal\s*(?:=\s*(?:async\s*)?)?\(\s*[^{}()]*,[^{}()]*,[^{}()]*\)'
match: 'not_contains'
target:
  source: file
  path: src/pages/portfolio/components/activities-list/index.tsx
---
