---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

add a query for a single transaction by hash to src/api/activity (GET /activities/{hash}, see openapi.json). an unknown hash is a 404 and we show a not-found screen for it, so it must not keep retrying
