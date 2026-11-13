---
type: regex
pattern: '(?:^|\s)//(?!\s*(?:TODO:|!|eslint-|@ts-))|/\*'
flags: 'm'
match: 'not_contains'
target:
  source: file
  path: src/pages/portfolio/hooks/use-search.ts
---
