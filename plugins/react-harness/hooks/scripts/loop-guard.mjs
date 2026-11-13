#!/usr/bin/env node
// The verify → refine → review loop of a running .planning/<name>/LOOP.md, as a state machine over the files on disk.
// PreToolUse(Skill): only the next stage runs, no verify or refine past max_iterations. PreToolUse(Write|Edit): LOOP.md
// takes only status: stopped from the model. PostToolUse(Skill): one log line per stage, each verify counts a round, the
// same criteria failing twice in a row is stuck. PostToolUse(Write|Edit): a code edit asks for a new verify. Stop: the
// turn does not end while a stage is left. No LOOP.md running → no-op.

import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const STAGES = ["verify", "refine", "review"];

const LOCKED = ["iteration", "max_iterations", "edited_after_verify"];

const read = (path) => (existsSync(path) ? readFileSync(path, "utf8") : null);

const field = (text, name) => text?.match(new RegExp(`^${name}:\\s*(.+)$`, "m"))?.[1].trim() ?? null;

const setField = (text, name, value) => {
  const pattern = new RegExp(`^${name}:.*$`, "m");
  if (pattern.test(text)) {
    return text.replace(pattern, `${name}: ${value}`);
  }
  return text.replace(/\n---\n/, `\n${name}: ${value}\n---\n`);
};

const body = (text) => text.split(/^---$/m).slice(2).join("---").trim();

const ids = (list) => (list?.match(/AC-\d+/g) ?? []).sort().join(", ");

const planningDir = (start) => {
  for (let dir = start; dir !== dirname(dir); dir = dirname(dir)) {
    if (existsSync(join(dir, ".planning"))) {
      return join(dir, ".planning");
    }
  }
  return null;
};

const runningLoop = (cwd) => {
  const planning = planningDir(cwd);
  if (!planning) {
    return null;
  }
  const name = readdirSync(planning).find((entry) => field(read(join(planning, entry, "LOOP.md")), "status") === "running");
  if (!name) {
    return null;
  }
  const dir = join(planning, name);
  return { name, path: join(dir, "LOOP.md"), verifyPath: join(dir, "VERIFY.md"), reviewPath: join(dir, "REVIEW.md") };
};

const stamp = () => new Date().toISOString().slice(11, 16);

const append = ({ loop, text, line }) => {
  writeFileSync(loop.path, `${text.trimEnd()}\n${line}\n`);
};

const logVerify = ({ loop, text }) => {
  const verify = read(loop.verifyPath);
  const status = field(verify, "status");
  const fail = field(verify, "fail") ?? "[]";
  const previous = [...text.matchAll(/^- \d+ · \S+ · verify (\S+) · fail (.*)$/gm)].at(-1);
  const round = Number(field(text, "iteration") ?? 0) + 1;
  const counted = setField(setField(text, "iteration", round), "edited_after_verify", "false");
  const line = `- ${round} · ${stamp()} · verify ${status} · fail ${fail}`;
  const stuck = status === "failed" && previous?.[1] === "failed" && ids(previous[2]) === ids(fail) && ids(fail) !== "";
  if (!stuck) {
    append({ loop, text: counted, line });
    return null;
  }
  append({ loop, text: setField(counted, "status", "stuck"), line: `${line}\n- ${stamp()} · stuck · ${ids(fail)} failed twice in a row` });
  return `The loop for ${loop.name} is stuck: ${ids(fail)} failed in two verify rounds in a row. Do not refine again; report the criteria still failing and stop.`;
};

const logStage = ({ loop, text, stage }) => {
  if (stage === "verify") {
    return logVerify({ loop, text });
  }
  if (stage === "refine") {
    append({ loop, text, line: `  · ${stamp()} · refine` });
    return null;
  }
  append({ loop, text, line: `  · ${stamp()} · review ${field(read(loop.reviewPath), "status") ?? "none"}` });
  return null;
};

const nextStage = ({ loop, text }) => {
  const verify = read(loop.verifyPath);
  const review = read(loop.reviewPath);
  const status = field(verify, "status");
  if (!verify) {
    return { stage: "verify", reason: `Invoke react-feature-workflow:verify ${loop.name}.` };
  }
  if (field(text, "edited_after_verify") === "true") {
    return { stage: "verify", reason: `The code changed after the last verify. Invoke react-feature-workflow:verify ${loop.name} again.` };
  }
  if (status === "failed") {
    return { stage: "refine", reason: `VERIFY.md is failed (${field(verify, "fail")}). Invoke react-feature-workflow:refine ${loop.name} on its open items.` };
  }
  if (status === "done" || status === "partial") {
    return { stage: "verify", reason: `refine touched VERIFY.md. Invoke react-feature-workflow:verify ${loop.name} again.` };
  }
  if (!review) {
    return { stage: "review", reason: `VERIFY.md is ${status}. Invoke react-feature-workflow:review with .planning/${loop.name} in its arguments.` };
  }
  const reviewRefined = ["done", "partial"].includes(field(review, "status")) && statSync(loop.reviewPath).mtimeMs > statSync(loop.verifyPath).mtimeMs;
  if (reviewRefined) {
    return { stage: "verify", reason: `refine changed the code after the last verify. Invoke react-feature-workflow:verify ${loop.name} again.` };
  }
  return null;
};

const allowedStages = ({ loop, text }) => {
  const next = nextStage({ loop, text });
  if (next) {
    return { stages: [next.stage], reason: next.reason };
  }
  return { stages: existsSync(loop.reviewPath) ? ["refine"] : [], reason: "Every stage is done; report and end the turn." };
};

const loopEditRefusal = ({ loop, text, input, cwd }) => {
  if (!input.file_path || resolve(cwd, input.file_path) !== loop.path) {
    return null;
  }
  const after = input.content ?? text.replace(input.old_string ?? "", input.new_string ?? "");
  const kept = LOCKED.every((name) => field(after, name) === field(text, name)) && ["running", "stopped"].includes(field(after, "status")) && after.includes(body(text));
  if (kept) {
    return null;
  }
  return "LOOP.md is kept by the loop hook. The one change it takes is status: running → stopped, with the reason on a line below the log.";
};

const deny = (reason) => {
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: reason } }));
};

try {
  const payload = JSON.parse(readFileSync(0, "utf8"));
  const cwd = payload.cwd ?? process.cwd();
  const loop = runningLoop(process.env.CLAUDE_PROJECT_DIR ?? cwd);
  if (!loop) {
    process.exit(0);
  }
  const text = read(loop.path);
  const iteration = Number(field(text, "iteration") ?? 0);
  const max = Number(field(text, "max_iterations") ?? 4);
  const input = payload.tool_input ?? {};
  const stage = STAGES.find((name) => new RegExp(`(?:^|:)${name}$`).test(input.skill ?? ""));
  const isWrite = payload.tool_name === "Write" || payload.tool_name === "Edit";

  if (payload.hook_event_name === "PreToolUse") {
    if (isWrite) {
      const refusal = loopEditRefusal({ loop, text, input, cwd });
      if (refusal) {
        deny(refusal);
      }
      process.exit(0);
    }
    if (!stage) {
      process.exit(0);
    }
    const reviewRefine = stage === "refine" && !nextStage({ loop, text }) && existsSync(loop.reviewPath);
    if (reviewRefine) {
      append({ loop, text: setField(text, "max_iterations", Math.max(max, iteration + 1)), line: `  · ${stamp()} · refine of the review findings · one more round` });
      process.exit(0);
    }
    if ((stage === "verify" || stage === "refine") && iteration >= max) {
      append({ loop, text: setField(text, "status", "capped"), line: `- ${stamp()} · ${stage} refused · cap of ${max} rounds reached` });
      deny(`The loop for ${loop.name} reached ${max} rounds. Do not run ${stage}; report the criteria still failing and stop.`);
      process.exit(0);
    }
    const { stages, reason } = allowedStages({ loop, text });
    if (!stages.includes(stage)) {
      append({ loop, text, line: `  · ${stamp()} · ${stage} refused · out of order` });
      deny(`${stage} is out of order in the loop for ${loop.name}. ${reason}`);
    }
    process.exit(0);
  }

  if (payload.hook_event_name === "PostToolUse") {
    if (isWrite) {
      const codeEdit = input.file_path && !resolve(cwd, input.file_path).includes("/.planning/");
      if (codeEdit && field(text, "edited_after_verify") !== "true") {
        writeFileSync(loop.path, setField(text, "edited_after_verify", "true"));
      }
      process.exit(0);
    }
    const context = stage ? logStage({ loop, text, stage }) : null;
    if (context) {
      console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: context } }));
    }
    process.exit(0);
  }

  const next = nextStage({ loop, text });
  if (!next) {
    append({ loop, text: setField(text, "status", "finished"), line: `- ${stamp()} · finished` });
    process.exit(0);
  }
  if (next.stage !== "review" && iteration >= max) {
    append({ loop, text: setField(text, "status", "capped"), line: `- ${stamp()} · cap of ${max} rounds reached · left: ${next.reason}` });
    process.exit(0);
  }
  console.log(JSON.stringify({ decision: "block", reason: `[loop ${iteration}/${max}] ${next.reason}` }));
} catch {}

process.exit(0);
