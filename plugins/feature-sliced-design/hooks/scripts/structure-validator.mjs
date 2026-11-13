#!/usr/bin/env node
// PreToolUse(Write|Edit): the four checks of the Feature-Sliced Design structure, in the
// order they ran as separate scripts. The first violation refuses the call. Every write
// under src/ is checked, old file or new — this plugin assumes all of src/ is FSD.

import { readFileSync } from "node:fs";
import { basename } from "node:path";

const LAYERS = ["app", "pages", "widgets", "features", "entities", "shared"];

const relative = (file) => file.slice(file.indexOf("src/") + "src/".length);

const toKebab = (name) =>
  [...name].map((c, i) => (/[A-Z]/.test(c) ? (i > 0 ? "-" : "") + c.toLowerCase() : c)).join("");

const layerOf = (file) =>
  new RegExp(`/src/(${LAYERS.join("|")})/`).exec(file)?.[1] ?? "";

const fsdLayer = ({ file }) => {
  if (!file.includes("/src/")) return null;
  const rel = relative(file);
  if (!rel.includes("/")) return null;
  if (LAYERS.includes(rel.slice(0, rel.indexOf("/")))) return null;
  return [
    `FSD violation: 'src/${rel}'`,
    `Allowed layers: src/{${LAYERS.join(",")}}/`,
    "Use shared/lib for utils, shared/hooks for hooks, features/*/ui for feature components",
  ];
};

const kebabCase = ({ file }) => {
  if (!file.includes("/src/")) return null;
  const filename = basename(file);
  const dot = filename.lastIndexOf(".");
  const name = dot < 0 ? filename : filename.slice(0, dot);
  if (/[A-Z]/.test(name))
    return [`Naming violation: '${filename}' is not kebab-case`, `Expected: '${toKebab(name)}'`];
  if (name.includes("_"))
    return [
      `Naming violation: '${filename}' uses underscores instead of hyphens`,
      `Expected: '${name.replaceAll("_", "-")}'`,
    ];
  return null;
};

const barrelImport = ({ file, content }) => {
  if (!content || !/\.(ts|tsx|js|jsx)$/.test(file)) return null;
  if (file.includes("/shared/ui/")) return null;
  if (!/from\s+["']@\/shared\/ui["']/.test(content)) return null;
  return [
    "Import violation: barrel import from '@/shared/ui' is not allowed",
    "Import directly: '@/shared/ui/button', '@/shared/ui/card', etc.",
  ];
};

const UI_PATHS = ["/ui/", "/components/", "/pages/", "/layouts/"];

const modelPlacement = ({ file, content }) => {
  const placement = (what, where) => [
    `[model-placement-validator] Placement violation: ${what}`,
    where,
  ];

  if (!content) return null;
  if (/\.(test|spec)\.(ts|tsx)$|\.stories\.tsx$/.test(file)) return null;

  const layer = layerOf(file);
  const lines = content.split("\n");

  if (layer && layer !== "shared") {
    const rank = LAYERS.indexOf(layer);
    for (const line of lines) {
      const imported = new RegExp(`from\\s+["']@/(${LAYERS.join("|")})/`).exec(line)?.[1];
      if (!imported || LAYERS.indexOf(imported) > rank) continue;
      return placement(
        `src/${layer}/ imports from src/${imported}/, which is the same layer or above it`,
        "A layer may import only layers strictly below it: app -> pages -> widgets -> features -> entities -> shared. An entity must not import another entity; a feature must not import another feature.",
      );
    }
  }

  if (layer === "entities" && /useMutation\(/.test(content))
    return placement(
      "an entity module calls useMutation()",
      "Mutations live in the feature that performs the write, not in the entity it writes to.",
    );

  if (!file.endsWith(".tsx") || !UI_PATHS.some((part) => file.includes(part))) return null;

  for (const line of lines) {
    const declared = /^export (interface|type) ([A-Za-z0-9_]+)/.exec(line);
    if (!declared || /(Props|State|Ref)$/.test(declared[2])) continue;
    return placement(
      `a domain type/interface ("${declared[2]}") is defined in a UI file`,
      "Domain types go in model/types.ts.",
    );
  }

  let declaredConst = false;
  for (const line of lines) {
    if (/^export const [A-Za-z0-9_]+ = \{/.test(line)) declaredConst = true;
    if (declaredConst && /\} as const/.test(line))
      return placement(
        "an enum-like constant is defined in a UI file",
        "Move it to model/constants.ts.",
      );
  }

  if (/z\.object\(|z\.(string|number|enum)\(/.test(content))
    return placement(
      "a zod schema is defined in a UI file",
      "Schemas go in model/schemas.ts, never inline in a component.",
    );

  if (lines.some((line) => /^export (const|function) use[A-Z]/.test(line)))
    return placement("a hook is defined in a UI file", "Move it to hooks/use-<name>.ts.");

  if (/httpClient\.|axios\.|fetch\(/.test(content))
    return placement(
      "an HTTP call is made directly in a UI file",
      "HTTP calls live in api/, never inline in a component.",
    );

  return null;
};

try {
  const input = JSON.parse(readFileSync(0, "utf8"))?.tool_input ?? {};
  const file = input.file_path;
  if (typeof file !== "string" || !file) process.exit(0);

  const subject = { file, content: input.new_string || input.content || "" };

  for (const check of [fsdLayer, kebabCase, barrelImport, modelPlacement]) {
    const violation = check(subject);
    if (!violation) continue;
    console.error(violation.join("\n"));
    process.exit(2);
  }
} catch {}

process.exit(0);
