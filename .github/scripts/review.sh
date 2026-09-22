#!/usr/bin/env bash
# Posts SARIF findings as PR review comments and exits 1 if any remain.
# Usage: review.sh <name> <sarif> [<baseline-sarif>]
# With a baseline, only findings absent from it count. A finding on a line the PR adds
# gets an inline comment; one whose rule is listed in DIR_RULES gets a file
# comment on a file the PR adds or changes in the same directory; others go to the log.
# Needs GH_TOKEN, PR, HEAD_SHA and GITHUB_REPOSITORY.
set -euo pipefail

name=$1
sarif=$2
baseline=${3:-}
marker="<!-- review.sh:$name -->"
repo="repos/$GITHUB_REPOSITORY"

files=$(gh api --paginate "$repo/pulls/$PR/files" | jq -s -c 'add')

report=$(jq -c -n \
  --slurpfile head "$sarif" \
  --slurpfile base "${baseline:-/dev/null}" \
  --argjson files "$files" \
  --arg root "$PWD/" \
  --arg marker "$marker" \
  --argjson dir_rules "$(jq -c -n --arg r "${DIR_RULES:-}" '$r | split(" ")')" '
  def dir: if test("/") then sub("/[^/]*$"; "") else "" end;
  def results: [.runs[].results[] | {
      rule: .ruleId,
      path: (.locations[0].physicalLocation.artifactLocation.uri | sub("^file://"; "") | ltrimstr($root)),
      line: .locations[0].physicalLocation.region.startLine,
      message: .message.text
    } | .key = [
      .rule,
      (if .rule | IN($dir_rules[]) then .path | dir else .path end),
      (.message | gsub("[0-9]+"; "N"))
    ]];

  [$files[] | select(.patch) | .filename as $path
   | foreach (.patch | split("\n")[]) as $l ({line: 0};
       if ($l | startswith("@@")) then {line: ($l | capture("\\+(?<n>[0-9]+)").n | tonumber), emit: false}
       elif ($l | startswith("+")) then {line: (.line + 1), emit: true, at: .line}
       elif ($l | startswith(" ")) then {line: (.line + 1), emit: false}
       else .emit = false
       end;
       select(.emit) | {path: $path, line: .at})] as $diff
  | [$files[] | select(.status != "removed")] as $live
  | ($base | map(results[])) as $b
  | [$head[0] | results[] | .in_diff = ({path, line} as $k | $diff | any(. == $k))]
  | [group_by(.key)[] | .[0].key as $k
     | ([$b[] | select(.key == $k)] | length) as $nb
     | sort_by(.in_diff) | .[$nb:][]]
  | map(. as $f | .comment = (
      "**\($f.rule)** \($f.message)\n\n\($marker)" as $body
      | if $f.in_diff then {path: $f.path, line: $f.line, body: $body}
        elif ($f.rule | IN($dir_rules[])) then
          ([$live[] | select(.filename | dir == ($f.path | dir))]
           | map(select(.status == "added")) + . | .[0].filename) as $anchor
          | if $anchor then {path: $anchor, subject_type: "file", body: $body} else null end
        else null end))
  | {new: ., comments: (map(.comment | values) | unique), log: map(select(.comment == null))}')

existing=$(gh api --paginate "$repo/pulls/$PR/comments" | jq -s -c --arg marker "$marker" '
  [add[] | select(.body | endswith($marker)) | {id, path, line, body}]')

same='.path == $c.path and .line == $c.line and .body == $c.body'

jq -r -n --argjson e "$existing" --argjson r "$report" "
  \$e[] | select(. as \$c | \$r.comments | any($same) | not) | .id" |
  while read -r id; do
    gh api -X DELETE "$repo/pulls/comments/$id" > /dev/null
  done

jq -c -n --argjson e "$existing" --argjson r "$report" --arg sha "$HEAD_SHA" "
  \$r.comments[] | select(. as \$c | \$e | any($same) | not)
  | . + {commit_id: \$sha} + (if .line then {side: \"RIGHT\"} else {} end)" |
  while read -r comment; do
    gh api -X POST "$repo/pulls/$PR/comments" --input - <<< "$comment" > /dev/null
  done

jq -r '.log[] | "\(.path):\(.line): \(.rule) \(.message)"' <<< "$report"
jq -r --arg name "$name" '"\($name): \(.new | length) finding(s), \(.comments | length) review comment(s)"' <<< "$report"
[ "$(jq '.new | length' <<< "$report")" -eq 0 ]
