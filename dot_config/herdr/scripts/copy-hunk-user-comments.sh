#!/bin/bash
set -euo pipefail

# Yank user comments from the active Hunk session to clipboard
# Format: filename:line-range\ncomment body

OUT=$(hunk session comment list --repo "$PWD" --type user --json 2>/dev/null)

if [ -z "$OUT" ] || [ "$(echo "$OUT" | jq '.comments | length')" -eq 0 ]; then
	echo "No user comments found in the current Hunk session."
	exit 1
fi

TEXT=$(echo "$OUT" | jq -r '
  .comments[] |
  "\(.filePath):\(
    if .newRange then
      if .newRange[0] == .newRange[1] then
        "L\(.newRange[0])"
      else
        "L\(.newRange[0])-L\(.newRange[1])"
      end
    elif .oldRange then
      if .oldRange[0] == .oldRange[1] then
        "L\(.oldRange[0])"
      else
        "L\(.oldRange[0])-L\(.oldRange[1])"
      end
    else
      "hunk \(.hunkIndex + 1)"
    end
  )\n\(.body)"
')

COUNT=$(echo "$OUT" | jq '.comments | length')

echo "$TEXT" | pbcopy
echo "Yanked $COUNT comment(s)"
