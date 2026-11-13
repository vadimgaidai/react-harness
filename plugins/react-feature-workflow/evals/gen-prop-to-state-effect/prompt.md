---
max_turns: 30
timeout_seconds: 600
tags: [conventions]
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

BlurSwapText in src/components/charts/blur-swap-text.tsx should fade from the old text to the new one: when `value` changes keep the previous value rendered underneath (opacity-0) alongside the new one
