#!/usr/bin/env node
// SessionStart and SubagentStart: tells the session, or a subagent that writes code, which
// convention skills to call before writing. The text is ../session-skills.md; the rules stay in the skills.

import { readFileSync } from "node:fs";

const eventName = () => {
  try {
    return JSON.parse(readFileSync(0, "utf8")).hook_event_name ?? "SessionStart";
  } catch {
    return "SessionStart";
  }
};

try {
  const additionalContext = readFileSync(new URL("../session-skills.md", import.meta.url), "utf8").trim();
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: eventName(), additionalContext } }));
} catch {}

process.exit(0);
