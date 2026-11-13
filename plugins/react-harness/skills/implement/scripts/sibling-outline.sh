#!/bin/bash
# Deterministic module outline — the cheap form of "read the sibling module".
#
# Usage:
#   sibling-outline.sh <module-dir>
#
# Prints what a tone reference is actually read for: the files and their sizes,
# the barrel verbatim, every file short enough to print whole (a signature saves
# nothing over a 10-line body and costs a Read), every exported signature of the
# longer files with its `path:line`, the cache keys, and the packages the module
# imports. Reading a long file whole costs 10-100x and adds nothing a signature
# doesn't carry. Read a range afterwards only where one isn't enough — every
# line below is addressable.
#
# No temp files, no here-documents: sandboxed shells (eval runs, a restricted
# TMPDIR) deny mktemp, and bash < 5.1 backs here-documents with temp files too.
# The file list lives in a variable and loops read it through process substitution.
#
# Env:
#   SIBLING_OUTLINE_MAX_FILES  cap on listed files (default 60)
#   SIBLING_OUTLINE_MAX_SIGS   cap on signatures per file (default 12)
#   SIBLING_OUTLINE_INLINE_LINES   a file this short or shorter is printed whole (default 60)
#   SIBLING_OUTLINE_INLINE_BUDGET  total lines printed whole across such files (default 240)

set -uo pipefail

err() { echo "sibling-outline: $1" >&2; exit 1; }

[ $# -ge 1 ] || err "usage: sibling-outline.sh <module-dir>"

DIR="${1%/}"
[ -d "$DIR" ] || err "'$DIR' is not a directory"

MAX_FILES="${SIBLING_OUTLINE_MAX_FILES:-60}"
MAX_SIGS="${SIBLING_OUTLINE_MAX_SIGS:-12}"
INLINE_LINES="${SIBLING_OUTLINE_INLINE_LINES:-60}"
INLINE_BUDGET="${SIBLING_OUTLINE_INLINE_BUDGET:-240}"
WIDTH=110

FILES="$(find "$DIR" -type f \
  \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) \
  ! -name '*.d.ts' ! -name '*.test.*' ! -name '*.spec.*' \
  ! -path '*/__tests__/*' ! -path '*/node_modules/*' \
  2>/dev/null | LC_ALL=C sort)"
[ -n "$FILES" ] || err "no source files under '$DIR'"
files() { printf '%s\n' "$FILES"; }

COUNT="$(files | wc -l | tr -d ' ')"

TOTAL=0
while IFS= read -r f; do
  n="$(wc -l < "$f" | tr -d ' ')"
  TOTAL=$((TOTAL + n))
done < <(files)

printf '%s — %s files, %s lines\n' "$DIR" "$COUNT" "$TOTAL"

# --- files ---
printf '\nFiles\n'
i=0
while IFS= read -r f; do
  i=$((i + 1))
  if [ "$i" -gt "$MAX_FILES" ]; then
    printf '  (+%s more files)\n' "$((COUNT - MAX_FILES))"
    break
  fi
  n="$(wc -l < "$f" | tr -d ' ')"
  printf '  %-48s %5s\n' "${f#"$DIR"/}" "$n"
done < <(files)

# --- barrel, verbatim: it is the module's public API and it is small ---
BARREL=""
for candidate in "$DIR/index.ts" "$DIR/index.tsx"; do
  if [ -f "$candidate" ]; then BARREL="$candidate"; break; fi
done
if [ -n "$BARREL" ]; then
  printf '\nBarrel (%s)\n' "$BARREL"
  grep -vE '^[[:space:]]*(//|/\*|\*|\*/|$)' "$BARREL" 2>/dev/null | sed 's/^/  /' || true
fi

# --- short files, whole: the runtime pattern lives in their bodies, and a signature
#     of a 10-line file saves nothing while costing a Read round-trip ---
INLINED=""
used=0
while IFS= read -r f; do
  [ "$f" = "$BARREL" ] && continue
  n="$(wc -l < "$f" | tr -d ' ')"
  [ "$n" -le "$INLINE_LINES" ] || continue
  [ $((used + n)) -le "$INLINE_BUDGET" ] || continue
  [ -z "$INLINED" ] && printf '\nShort files (whole)\n'
  used=$((used + n))
  INLINED="$INLINED$f
"
  awk -v file="$f" 'NF { printf "  %s:%d  %s\n", file, NR, $0 }' "$f" 2>/dev/null
  printf '\n'
done < <(files)
is_inlined() { printf '%s' "$INLINED" | grep -qFx -- "$1"; }

# --- exported signatures of the longer files, addressable by path:line ---
printf 'Exports (longer files)\n'
found_exports=0
while IFS= read -r f; do
  [ "$f" = "$BARREL" ] && continue
  is_inlined "$f" && continue
  sigs="$(grep -nE '^[[:space:]]*export[[:space:]]' "$f" 2>/dev/null)" || true
  [ -z "$sigs" ] && continue
  found_exports=1
  printf '%s\n' "$sigs" | head -n "$MAX_SIGS" | while IFS= read -r line; do
    lineno="${line%%:*}"
    text="${line#*:}"
    text="$(printf '%s' "$text" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ ?\{[[:space:]]*$//; s/ ?=>[[:space:]]*$//')"
    if [ "${#text}" -gt "$WIDTH" ]; then text="${text:0:$WIDTH}…"; fi
    printf '  %s:%s  %s\n' "$f" "$lineno" "$text"
  done
  total_sigs="$(printf '%s\n' "$sigs" | wc -l | tr -d ' ')"
  if [ "$total_sigs" -gt "$MAX_SIGS" ]; then
    printf '  (+%s more exports in %s)\n' "$((total_sigs - MAX_SIGS))" "$f"
  fi
done < <(files)
[ "$found_exports" -eq 0 ] && printf '  (none)\n'

# --- key factories, body included: the shape a data layer is mirrored for ---
KEYS="$(while IFS= read -r f; do
  is_inlined "$f" && continue
  awk -v file="$f" '
    /[Kk]eys[[:space:]]*[:=][[:space:]]*\{/ { inside = 1 }
    inside { printf "%s:%d  %s\n", file, NR, $0 }
    inside && /^[[:space:]]*\}/ { inside = 0 }
  ' "$f" 2>/dev/null
done < <(files))" || true
if [ -n "$KEYS" ]; then
  printf '\nKey factories\n'
  printf '%s\n' "$KEYS" | head -n 24 | sed -E 's/^/  /'
fi

# --- external imports: which client, which query lib, which aliases ---
IMPORTS="$(while IFS= read -r f; do
  grep -hoE "from[[:space:]]+['\"][^'\"]+['\"]" "$f" 2>/dev/null
done < <(files) | sed -E "s/.*['\"]([^'\"]+)['\"]/\1/" | grep -v '^\.' | LC_ALL=C sort -u)" || true
if [ -n "$IMPORTS" ]; then
  printf '\nImports (external)\n'
  printf '%s\n' "$IMPORTS" | sed 's/^/  /'
fi

printf '\nShort files are printed whole above. Read a range of a longer file only where its signature is not enough.\n'
