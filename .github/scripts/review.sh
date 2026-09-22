#!/usr/bin/env bash
# Posts SARIF findings as inline PR review comments on lines the PR diff touches,
# keeping comments that still match and deleting ones that no longer do.
# Usage: review.sh <sarif-file> <name>; needs GH_TOKEN, PR, HEAD_SHA, GITHUB_REPOSITORY.
set -euo pipefail

sarif=$1
name=$2
marker="<!-- review.sh:$name -->"
repo="repos/$GITHUB_REPOSITORY"

findings=$(jq -c --arg root "$PWD/" --arg marker "$marker" '
  [.runs[].results[] | {
    path: (.locations[0].physicalLocation.artifactLocation.uri | sub("^file://"; "") | ltrimstr($root)),
    line: .locations[0].physicalLocation.region.startLine,
    body: "**\(.ruleId)** \(.message.text)\n\n\($marker)"
  }] | unique' "$sarif")

diff_lines=$(gh api --paginate "$repo/pulls/$PR/files" | jq -s -c '
  [.[][] | select(.patch) | .filename as $path
   | foreach (.patch | split("\n")[]) as $l ({line: 0};
       if ($l | startswith("@@")) then {line: ($l | capture("\\+(?<n>[0-9]+)").n | tonumber), emit: false}
       elif ($l | startswith("-")) or ($l | startswith("\\")) then .emit = false
       else {line: (.line + 1), emit: true, at: .line}
       end;
       select(.emit) | {path: $path, line: .at})]')

inline=$(jq -c -n --argjson f "$findings" --argjson d "$diff_lines" '
  $f | map(. as $x | select($d | any(. == {path: $x.path, line: $x.line})))')

existing=$(gh api --paginate "$repo/pulls/$PR/comments" | jq -s -c --arg marker "$marker" '
  [.[][] | select(.body | endswith($marker)) | {id, path, line, body}]')

jq -r -n --argjson e "$existing" --argjson i "$inline" '
  $e[] | select(. as $c | $i | any(.path == $c.path and .line == $c.line and .body == $c.body) | not) | .id' |
  while read -r id; do
    gh api -X DELETE "$repo/pulls/comments/$id" > /dev/null
  done

jq -c -n --argjson e "$existing" --argjson i "$inline" --arg sha "$HEAD_SHA" '
  $i[] | select(. as $f | $e | any(.path == $f.path and .line == $f.line and .body == $f.body) | not)
  | . + {commit_id: $sha, side: "RIGHT"}' |
  while read -r comment; do
    gh api -X POST "$repo/pulls/$PR/comments" --input - <<< "$comment" > /dev/null
  done

echo "$name: $(jq length <<< "$findings") finding(s), $(jq length <<< "$inline") on lines in the PR diff"
