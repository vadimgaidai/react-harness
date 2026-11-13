#!/bin/bash
# Script-checkable half of structure/references/reviewing.md — the list that
# needs no judgment: a module missing its barrel, a barrel re-exporting a file that does
# not exist, a `use-*.ts` outside `hooks/`. Everything else in that file stays a
# judgment call for `review`'s `structure` angle.
#
# Usage: structure-check.sh <changed-file ...>
#
# Only `src/features/<name>`, `src/pages/<name>`, `src/layouts/<name>` and
# `src/api/<resource>` are modules with a barrel; a changed file outside those is skipped.

set -uo pipefail

[ $# -ge 1 ] || { echo "usage: structure-check.sh <changed-file ...>" >&2; exit 1; }

module_dir() {
  case "$1" in
    */features/*|*/pages/*|*/layouts/*|*/api/*)
      printf '%s\n' "$1" | sed -E 's#^(.*/(features|pages|layouts|api)/[^/]+)/.*#\1#'
      ;;
  esac
}

MODULES="$(for f in "$@"; do module_dir "$f"; done | LC_ALL=C sort -u)"
[ -n "$MODULES" ] || exit 0

status=0

resolve_import() {
  local from="$1" spec="$2"
  [[ "$spec" == .* ]] || return 0
  local target
  target="$(cd "$(dirname "$from")" 2>/dev/null && printf '%s/%s\n' "$PWD" "$spec")" || return 1
  for cand in "$target" "$target.ts" "$target.tsx" "$target/index.ts" "$target/index.tsx"; do
    [ -e "$cand" ] && return 0
  done
  return 1
}

while IFS= read -r mod; do
  [ -n "$mod" ] || continue
  [ -d "$mod" ] || continue

  barrel=""
  for cand in "$mod/index.ts" "$mod/index.tsx"; do
    [ -f "$cand" ] && barrel="$cand" && break
  done
  if [ -z "$barrel" ]; then
    echo "$mod: no barrel (index.ts) — a module's public surface has no file to read"
    status=1
    continue
  fi

  while IFS= read -r line; do
    spec="$(printf '%s' "$line" | sed -E "s/.*from[[:space:]]+['\"]([^'\"]+)['\"].*/\1/")"
    [ "$spec" = "$line" ] && continue
    resolve_import "$barrel" "$spec" || {
      echo "$barrel: re-exports '$spec', which does not resolve to a file"
      status=1
    }
  done < <(grep -E "^export .* from ['\"]" "$barrel" 2>/dev/null)

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in
      use-*.ts|use-*.tsx)
        case "$f" in
          */hooks/*) ;;
          *) echo "$f: a use-*.ts hook outside hooks/"; status=1 ;;
        esac
        ;;
    esac
  done < <(find "$mod" -type f \( -name 'use-*.ts' -o -name 'use-*.tsx' \) 2>/dev/null)
done <<<"$MODULES"

exit $status
