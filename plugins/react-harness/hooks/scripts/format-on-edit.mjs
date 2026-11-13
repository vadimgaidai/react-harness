#!/usr/bin/env node
// PostToolUse(Edit|Write): formats the touched file with the project's own Prettier.
// Agents never spend tokens on formatting; the reviewer never checks it.
// Does nothing when the project has no Prettier.

import { execFileSync } from "node:child_process";
import { accessSync, constants, existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const FORMATTED = new Set([".ts", ".tsx", ".js", ".jsx", ".json", ".css", ".scss", ".html"]);
const SKIPPED = ["/node_modules/", "/dist/", "/.git/"];

try {
  const file = JSON.parse(readFileSync(0, "utf8"))?.tool_input?.file_path;
  if (typeof file !== "string" || !file) process.exit(0);
  if (SKIPPED.some((part) => file.includes(part))) process.exit(0);

  const ext = file.slice(file.lastIndexOf("."));
  if (!FORMATTED.has(ext) || !existsSync(file)) process.exit(0);

  const prettier = join(process.env.CLAUDE_PROJECT_DIR ?? ".", "node_modules/.bin/prettier");
  accessSync(prettier, constants.X_OK);
  execFileSync(prettier, ["--write", file], { stdio: "ignore" });
} catch {}

process.exit(0);
