---
type: regex
pattern: 'updateActivity\s*=\s*(?:async\s*)?\([^=]*?\)\s*:\s*Promise<\s*IActivitiesListResponse|patch<\s*IActivitiesListResponse'
match: 'not_contains'
target:
  source: file
  path: src/api/activity/api.ts
---
