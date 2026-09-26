#!/usr/bin/env bash
# Fails unless the current checkout is the merge of the PR's head commit, so a stale
# refs/pull/N/merge can't be checked in place of what the PR now contains.
# Usage: check-merge.sh <head-sha>
set -euo pipefail

if [[ $(git rev-parse HEAD^2) != "$1" ]]; then
  echo "::error::The PR merge commit is out of date with the PR head; re-run this check"
  exit 1
fi
