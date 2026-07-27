#!/bin/bash
set -euo pipefail

# Yank user comments from the active Hunk session to clipboard
# Format: filename:line-range\ncomment body

OUT=$(hunk session comment list --repo "$PWD" --type user --json 2>/dev/null)

[ -z "$OUT" ] && echo "No user comments found." && exit 1

COUNT=$(echo "$OUT" | jq '.comments | length')
[ "$COUNT" -eq 0 ] && echo "No user comments found." && exit 1

TEXT=$(echo "$OUT" | jq -r '
  .comments[] |
  "\(.filePath):\(
    (.newRange // .oldRange) as $r |
    if $r then
      if $r[0] == $r[1] then "L\($r[0])"
      else "L\($r[0])-L\($r[1])"
      end
    else
      "hunk \(.hunkIndex + 1)"
    end
  )\n\(.body)"
')

echo "$TEXT" | pbcopy
echo "Yanked $COUNT comment(s)"
