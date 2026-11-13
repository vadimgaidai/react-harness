---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Chart in src/components/charts/chart.tsx ignores isLoading and isError. show the Skeleton while loading, an error text if it failed, an empty text when there are no points, otherwise the chart
