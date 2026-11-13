---
type: regex
pattern: 'updateActivity\s*=\s*(?:async\s*)?\([^=]*?\)\s*:\s*Promise<\s*IActivityTransaction\s*>|updateActivity[\s\S]{0,400}?patch<\s*IActivityTransaction\s*>'
target:
  source: file
  path: src/api/activity/api.ts
---
