---
type: regex
pattern: '\bh-(\d+(?:\.\d+)?)\s+w-\1\b|\bw-(\d+(?:\.\d+)?)\s+h-\2\b'
match: 'not_contains'
target:
  source: file
  path: src/pages/portfolio/components/activities-list/sync-banner.tsx
---
