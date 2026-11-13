---
type: regex
pattern: '\buseEffect\b|\buseLayoutEffect\b'
match: 'not_contains'
target:
  source: file
  path: src/components/charts/blur-swap-text.tsx
---
