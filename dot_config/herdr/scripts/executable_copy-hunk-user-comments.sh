#!/bin/bash
set -euo pipefail

# Copy user comments from the active Hunk session to clipboard
# Produces a numbered, structured summary suitable for pasting into an LLM.

OUT=$(hunk session comment list --repo "$PWD" --type user --json 2>/dev/null)

[ -z "$OUT" ] && echo "No user comments found." && exit 1

COUNT=$(echo "$OUT" | jq '.comments | length')
[ "$COUNT" -eq 0 ] && echo "No user comments found." && exit 1

TEXT=$(echo "$OUT" | jq -r '
  "Please checkout these locations and implement user comments",
  "",
  ([.comments[] | {
    loc: ((.newRange // .oldRange) as $r |
      "\(.filePath):\(
        if $r then
          if $r[0] == $r[1] then "\($r[0])"
          else "\($r[0])-\($r[1])"
          end
        else
          "hunk \(.hunkIndex + 1)"
        end
      )"),
    body: .body
  }] | to_entries[] | "\(.key + 1). \(.value.loc)\n\(.value.body)")
')

echo "$TEXT" | pbcopy
echo "Yanked $COUNT comment(s)"
