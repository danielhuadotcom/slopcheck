#!/usr/bin/env bash
# Lints the tracked .py files in the current checkout and writes SARIF to <out>.
# Config comes only from SLOPLINT_CONFIG, so a sloplint.toml in the tree is never read.
# Exits 0 on findings (the SARIF carries them) and non-zero only if sloplint itself fails.
# Usage: sloplint.sh <out>; needs SLOPLINT and SLOPLINT_CONFIG.
set -uo pipefail

out=$1
scripts=$(dirname "$0")
mapfile -d '' files < <("$scripts/tracked-files.sh" '*.py')

if ((${#files[@]} == 0)); then
  echo '{"runs": []}' > "$out"
  exit 0
fi

"$SLOPLINT" check --config "$SLOPLINT_CONFIG" --format sarif "${files[@]}" > "$out"
code=$?
if ((code > 1)); then
  echo "::error::sloplint failed with exit code $code"
  exit "$code"
fi
