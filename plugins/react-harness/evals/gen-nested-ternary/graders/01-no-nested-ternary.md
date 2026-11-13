---
type: regex
pattern: '\?(?![.?:])(?:(?!\n\s*(?:const|let|var|return|if|export|function)\b)[^;{}?])*:(?:(?!\n\s*(?:const|let|var|return|if|export|function)\b)[^;{}?])*\?(?![.?:])'
match: 'not_contains'
target:
  source: file
  path: src/components/charts/chart.tsx
---
