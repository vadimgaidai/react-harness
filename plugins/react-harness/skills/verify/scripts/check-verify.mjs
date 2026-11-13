#!/usr/bin/env node
// Exit check for the verify stage: VERIFY.md against SPEC.md in one .planning/<name>/ folder.
// Usage: node check-verify.mjs .planning/<name>
// Prints one line per problem and exits 1, or prints "ok" and exits 0.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2];
if (!dir) {
  console.error("usage: check-verify.mjs .planning/<name>");
  process.exit(2);
}

const STATUSES = ["ready", "failed", "checks-skipped"];
const BOX = { pass: ["x"], fail: [" ", "x"], manual: ["?"] };
const problems = [];

const read = (name) => {
  const path = join(dir, name);
  if (!existsSync(path)) {
    return null;
  }
  return readFileSync(path, "utf8");
};

const section = (text, heading) => {
  const start = text.search(new RegExp(`^## ${heading}\\s*$`, "m"));
  if (start < 0) {
    return "";
  }
  const rest = text.slice(start);
  const end = rest.indexOf("\n## ", 1);
  return end < 0 ? rest : rest.slice(0, end);
};

const ids = (text) => [...text.matchAll(/^AC-\d+\b/gm)].map((m) => m[0]);

const frontmatter = (text) => {
  const block = text.match(/^---\n([\s\S]*?)\n---/);
  const fields = {};
  if (!block) {
    return null;
  }
  for (const line of block[1].split("\n")) {
    const pair = line.match(/^([\w-]+):\s*(.*)$/);
    if (pair) {
      fields[pair[1]] = pair[2].trim();
    }
  }
  return fields;
};

const list = (value) => {
  const inner = (value ?? "").match(/^\[(.*)\]$/);
  if (!inner) {
    return null;
  }
  return inner[1].split(",").map((item) => item.trim()).filter(Boolean);
};

const checkLine = ({ id, verdict, line }) => {
  if (!line) {
    problems.push(`${id}: no line under ## Criteria`);
    return;
  }
  const box = line.match(/^- \[(.)\]/)?.[1];
  if (!BOX[verdict].includes(box)) {
    problems.push(`${id}: listed under ${verdict} but its box is [${box}]`);
  }
  if (verdict === "fail" && !/—\s*fail\b/.test(line)) {
    problems.push(`${id}: listed under fail but the line does not say fail`);
  }
  if (verdict === "manual" && !/\b1\.\s/.test(line)) {
    problems.push(`${id}: unverifiable needs numbered manual steps`);
  }
  if (verdict === "manual") {
    return;
  }
  const executed = /—\s*executed\b/.test(line);
  const isStatic = /—\s*static\b/.test(line);
  if (!executed && !isStatic) {
    problems.push(`${id}: no evidence tier (executed or static)`);
  }
  if (executed && !/`[^`]+`/.test(line)) {
    problems.push(`${id}: executed evidence needs the command in backticks`);
  }
  if (verdict === "pass" && isStatic && !/\S+\.\w+:\d+/.test(line)) {
    problems.push(`${id}: static evidence needs a file:line`);
  }
};

const spec = read("SPEC.md");
const verify = read("VERIFY.md");
if (spec === null) {
  problems.push("SPEC.md is missing");
}
if (verify === null) {
  problems.push("VERIFY.md is missing");
}

if (spec !== null && verify !== null) {
  const fields = frontmatter(verify);
  const specIds = ids(section(spec, "Acceptance criteria"));
  if (!specIds.length) {
    problems.push("SPEC.md: no AC- ids under ## Acceptance criteria");
  }
  if (!fields) {
    problems.push("VERIFY.md: no frontmatter");
  } else {
    if (!STATUSES.includes(fields.status)) {
      problems.push(`status must be one of ${STATUSES.join(", ")}; got "${fields.status ?? ""}"`);
    }
    if (!fields.scope) {
      problems.push("scope is empty");
    }
    const verdicts = {};
    for (const verdict of Object.keys(BOX)) {
      const members = list(fields[verdict]);
      if (!members) {
        problems.push(`${verdict}: must be a list, e.g. [AC-1, AC-2] or []`);
        continue;
      }
      for (const id of members) {
        if (verdicts[id]) {
          problems.push(`${id}: listed under both ${verdicts[id]} and ${verdict}`);
        }
        verdicts[id] = verdict;
      }
    }
    for (const id of specIds) {
      if (!verdicts[id]) {
        problems.push(`${id}: in the spec, in none of pass / fail / manual`);
      }
    }
    for (const id of Object.keys(verdicts)) {
      if (!specIds.includes(id)) {
        problems.push(`${id}: has a verdict but is not in the spec`);
      }
    }
    const lines = section(verify, "Criteria").split("\n");
    for (const [id, verdict] of Object.entries(verdicts)) {
      const line = lines.find((candidate) => new RegExp(`^- \\[.\\] ${id}\\b`).test(candidate));
      checkLine({ id, verdict, line });
    }
    const failed = Object.values(verdicts).includes("fail");
    if (failed && fields.status === "ready") {
      problems.push("status is ready while a criterion fails");
    }
    if (!failed && fields.status === "failed") {
      problems.push("status is failed while no criterion fails");
    }
  }
}

if (problems.length) {
  for (const problem of problems) {
    console.error(problem);
  }
  process.exit(1);
}
console.log("ok");
