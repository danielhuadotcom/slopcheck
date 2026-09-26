#!/usr/bin/env bash
# Fails if the PR touches CLAUDE.md or AGENTS.md, has a commit message over
# 80 characters, or leaves a README.md over 480 characters.
# Usage: pr-rules.sh <base-sha> <head-sha>, run from the PR merge commit.
set -euo pipefail
export LC_ALL=C.UTF-8

base=$1
head=$2
fail=0

while IFS= read -r path; do
  case ${path##*/} in
    CLAUDE.md | AGENTS.md)
      echo "::error file=$path::PR changes $path"
      fail=1
      ;;
  esac
done < <(git diff --no-renames --name-only "$base...$head")

for sha in $(git rev-list "$head" "^$base"); do
  msg=$(git log -1 --format=%B "$sha")
  len=$(printf '%s' "$msg" | wc -m)
  if ((len > 80)); then
    echo "::error::Commit ${sha:0:7} message is $len characters (max 80): $(git log -1 --format=%s "$sha")"
    fail=1
  fi
done

if [[ -f README.md ]]; then
  len=$(wc -m < README.md)
  if ((len > 480)); then
    echo "::error file=README.md::README.md is $len characters (max 480)"
    fail=1
  fi
fi

exit $fail
