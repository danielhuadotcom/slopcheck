#!/usr/bin/env bash
# Prints every tracked file matching the given pathspecs, NUL-separated, skipping symlinks.
# Linting this list instead of letting a tool walk the tree means .gitignore, .ignore files,
# hidden directories and tool excludes can't hide a file from the checks.
# Usage: tracked-files.sh <pathspec>...
set -euo pipefail

git ls-files -z -- "$@" | while IFS= read -r -d '' file; do
  [[ -L $file ]] || printf '%s\0' "$file"
done
