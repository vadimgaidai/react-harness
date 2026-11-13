---
name: api-contract
description: Slices an OpenAPI/Swagger contract down to the endpoints one feature needs, with $refs inlined and required/optional/enums explicit, so request and response shapes are never guessed. Use when starting work against a backend contract, when types drift from the API, or when the user gives a Swagger/OpenAPI URL.
---

# API contract

Reading a whole contract costs tens of thousands of tokens and still invites invented fields. Slice it instead.

## Use

```bash
node "${CLAUDE_PLUGIN_ROOT}"/skills/api-contract/scripts/contract-slice.mjs \
  <url-or-path> <out.md> "GET /pet/{petId}" "POST /pet"
```

- **Source**: a URL or a local file. OpenAPI 3.x and Swagger 2.0 both work.
- **Out**: write it next to the plan — `.planning/[name]/contract.md`.
- **Endpoints**: one `"METHOD /path"` per endpoint, paths exactly as the contract spells them (`{petId}`, not `:petId`). An unknown path fails loudly with the path count, rather than silently producing nothing.

Re-run with more endpoints to extend the slice. It is deterministic and safe to commit.

## What you get

Per operation: parameters table, request body and every response as an annotated example object where each leaf reads `type REQUIRED` or `type optional`, plus the explicit `Required:` list, enums expanded, `$ref`s inlined (cycle-safe), and the security scheme.

## Rules

- The slice is **authoritative**. When it disagrees with prose in a plan, ticket or comment, the slice wins — say so, then follow it.
- Never hand-write a shape "based on" the contract without slicing it first.
- A field absent from the slice does not exist. Do not add it because it seems likely.
- Nullability, formats (`int64`, `date-time`, `uuid`) and enum members carry into the types verbatim.

## When the contract is wrong

Backends drift. If the slice contradicts what the API actually returns, say so and name both shapes — do not silently code to the observed behavior, and do not silently code to a contract you know is stale.
