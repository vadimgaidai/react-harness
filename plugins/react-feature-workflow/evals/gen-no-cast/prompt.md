---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

the kind filter select hands us a plain string. in src/pages/portfolio/hooks/use-get-activities.ts keep the selected kind in state, expose a setter that takes that string, and send it as the kind filter
