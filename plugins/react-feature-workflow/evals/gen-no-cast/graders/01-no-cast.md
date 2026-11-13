---
type: regex
pattern: '\bas\s+(?:TransactionKind|IActivity\w*|unknown|any|string)\b'
match: 'not_contains'
target:
  source: file
  path: src/pages/portfolio/hooks/use-get-activities.ts
---
