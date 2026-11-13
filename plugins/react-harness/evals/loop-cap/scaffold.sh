#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/../verify-refine-loop/scaffold.sh"

sed -i.bak 's/^max_iterations: 4$/max_iterations: 1/' .planning/token-symbol/LOOP.md
rm .planning/token-symbol/LOOP.md.bak
