---
max_turns: 80
timeout_seconds: 1500
tags: [outcome]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add a portfolio balance chart to the portfolio page: an area chart of the balance over time with a 7d / 30d / 90d range switch. The endpoint is `GET /portfolio/history` in `openapi.json`; the backend is not ready, so the api function returns fake data shaped by the contract after a short delay. Show loading, empty and error states. Call the work balance-chart.
