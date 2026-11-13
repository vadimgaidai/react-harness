#!/usr/bin/env node
// PreToolUse(Write|Edit): the four checks of the feature-folders structure, in the order
// they ran as separate scripts. The first violation refuses the call with its own tag.
// Placement and naming only ever block a file that does not exist yet, so a legacy tree
// is never fought file by file; the content rules apply to every write, old file or new.

import { existsSync, readFileSync } from "node:fs";
import { basename } from "node:path";

const BUCKETS = "app|pages|layouts|features|components|hooks|providers|lib|config|api|assets";

const REDIRECTS = {
  utils: "Pure, domain-free functions go in src/lib/ instead.",
  helpers: "Pure, domain-free functions go in src/lib/ instead.",
  services: "HTTP calls and query/mutation hooks go in src/api/<resource>/ instead.",
  styles: "Global styles go in src/assets/; component-scoped styling stays beside the component.",
  constants: "An app-wide constant goes in src/config/; one used by a single module goes in that module's own constants.ts.",
  types: "A request/response shape goes in src/api/<resource>/types.ts; a module-local type goes in that module's own types.ts.",
  ui: "shadcn/base primitives go in src/components/ui/; a domain wrapper goes in src/components/ or the owning module's components/.",
};

const relative = (file) => file.slice(file.indexOf("src/") + "src/".length);

const toKebab = (name) =>
  [...name].map((c, i) => (/[A-Z]/.test(c) ? (i > 0 ? "-" : "") + c.toLowerCase() : c)).join("");

const bucketPlacement = ({ file, isNew }) => {
  if (!isNew || !file.includes("/src/")) return null;
  const rel = relative(file);
  if (!rel.includes("/")) return null;
  const bucket = rel.slice(0, rel.indexOf("/"));
  if (new RegExp(`^(${BUCKETS})$`).test(bucket)) return null;

  return [
    `[bucket-placement-validator] Placement violation: 'src/${bucket}/' is not a recognized bucket`,
    REDIRECTS[bucket] ?? `Allowed top-level buckets: src/{${BUCKETS.replaceAll("|", ",")}}/`,
  ];
};

const kebabCase = ({ file, isNew }) => {
  if (!isNew || !file.includes("/src/")) return null;
  const filename = basename(file);
  const dot = filename.lastIndexOf(".");
  const name = dot < 0 ? filename : filename.slice(0, dot);
  if (/[A-Z]/.test(name))
    return [
      `[kebab-case-validator] Naming violation: '${filename}' is not kebab-case`,
      `Expected: '${toKebab(name)}'`,
    ];
  if (name.includes("_"))
    return [
      `[kebab-case-validator] Naming violation: '${filename}' uses underscores instead of hyphens`,
      `Expected: '${name.replaceAll("_", "-")}'`,
    ];
  return null;
};

const barrelImport = ({ file, content }) => {
  if (!content || !/\.(ts|tsx|js|jsx)$/.test(file)) return null;
  if (file.includes("/components/ui/")) return null;
  if (!/from\s+["']@\/components\/ui["']/.test(content)) return null;
  return [
    "[barrel-import-validator] Import violation: barrel import from '@/components/ui' is not allowed",
    "Import directly: '@/components/ui/button', '@/components/ui/card', etc.",
  ];
};

const UI_PATHS = ["/ui/", "/components/", "/pages/", "/layouts/"];

const modelPlacement = ({ file, content }) => {
  const placement = (what, where) => [
    `[model-placement-validator] Placement violation: ${what}`,
    where,
  ];

  if (/\/(features|pages)\/[^/]+\/api\//.test(file))
    return placement(
      "a feature/page has its own 'api/' folder",
      "HTTP calls live in src/api/<resource>/, keyed by backend resource — never inside a feature or page module.",
    );

  if (!content) return null;
  if (/\.(test|spec)\.(ts|tsx)$|\.stories\.tsx$/.test(file)) return null;
  if (!file.endsWith(".tsx") || !UI_PATHS.some((part) => file.includes(part))) return null;

  const lines = content.split("\n");

  for (const line of lines) {
    const declared = /^export (interface|type) ([A-Za-z0-9_]+)/.exec(line);
    if (!declared || /(Props|State|Ref)$/.test(declared[2])) continue;
    return placement(
      `a domain type/interface ("${declared[2]}") is defined in a UI file`,
      "Domain types go in <module>/types.ts, or src/api/<resource>/types.ts for a request/response shape.",
    );
  }

  let declaredConst = false;
  for (const line of lines) {
    if (/^export const [A-Za-z0-9_]+ = \{/.test(line)) declaredConst = true;
    if (declaredConst && /\} as const/.test(line))
      return placement(
        "an enum-like constant is defined in a UI file",
        "Move it to <module>/constants.ts (src/config/ if it is app-wide).",
      );
  }

  if (/z\.object\(|z\.(string|number|enum)\(/.test(content))
    return placement(
      "a zod schema is defined in a UI file",
      "Schemas go in <module>/schemas.ts, never inline in a component.",
    );

  if (lines.some((line) => /^export (const|function) use[A-Z]/.test(line)))
    return placement("a hook is defined in a UI file", "Move it to <module>/hooks/use-<name>.ts.");

  if (/httpClient\.|axios\.|fetch\(/.test(content))
    return placement(
      "an HTTP call is made directly in a UI file",
      "HTTP calls live in src/api/<resource>/, never inline in a component.",
    );

  return null;
};

try {
  const input = JSON.parse(readFileSync(0, "utf8"))?.tool_input ?? {};
  const file = input.file_path;
  if (typeof file !== "string" || !file) process.exit(0);

  const subject = {
    file,
    isNew: !existsSync(file),
    content: input.new_string || input.content || "",
  };

  for (const check of [bucketPlacement, kebabCase, barrelImport, modelPlacement]) {
    const violation = check(subject);
    if (!violation) continue;
    console.error(violation.join("\n"));
    process.exit(2);
  }
} catch {}

process.exit(0);
