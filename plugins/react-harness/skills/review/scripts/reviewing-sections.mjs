#!/usr/bin/env node
// Prints each convention skill's references/reviewing.md, read at call time.
// Injected into review's SKILL.md, so the questions have one copy: the skill's own.

import { readFileSync } from "node:fs";

const SKILLS = ["code-shape", "typescript", "react", "ui-conventions", "error-handling", "tanstack-query", "react-hook-form-zod", "routing", "react-testing"];

const body = (text) => {
  const lines = text.split("\n");
  const start = lines.findIndex((line) => line.startsWith("Answers:"));
  let fenced = false;
  return lines
    .slice(start + 1)
    .map((line) => {
      if (line.startsWith("```")) {
        fenced = !fenced;
      }
      return !fenced && line.startsWith("#") ? `###${line}` : line;
    })
    .join("\n")
    .trim();
};

const questions = (name) => {
  try {
    return body(readFileSync(new URL(`../../${name}/references/reviewing.md`, import.meta.url), "utf8"));
  } catch {
    return "(references/reviewing.md not found)";
  }
};

console.log(SKILLS.map((name) => `### ${name}\n\n${questions(name)}`).join("\n\n"));
