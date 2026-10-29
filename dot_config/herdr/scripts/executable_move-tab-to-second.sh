#!/bin/bash
set -euo pipefail

# Move the focused tab to the second slot of its workspace.
# tab.move takes a pre-removal insertion index, so a tab that is already
# first needs insert_index 2 to land at index 1.

snapshot=$(herdr api snapshot)

tab_id=$(jq -r '.result.snapshot.focused_tab_id // empty' <<<"$snapshot")
[ -n "$tab_id" ] || exit 0

current_index=$(jq -r --arg t "$tab_id" '
  .result.snapshot.tabs as $tabs
  | ($tabs[] | select(.tab_id == $t) | .workspace_id) as $ws
  | [$tabs[] | select(.workspace_id == $ws) | .tab_id]
  | to_entries[] | select(.value == $t) | .key
' <<<"$snapshot")

# Already second: nothing to do.
[ "$current_index" != "1" ] || exit 0

insert_index=1
[ "$current_index" = "0" ] && insert_index=2

socket=$(herdr status server | awk -F': ' '$1 == "socket" { print $2 }')
[ -n "$socket" ] || {
  echo "Could not determine the Herdr server socket" >&2
  exit 1
}

request=$(jq -cn --arg tab_id "$tab_id" --argjson idx "$insert_index" '{
  id: "move-tab-to-second",
  method: "tab.move",
  params: {tab_id: $tab_id, insert_index: $idx}
}')

response=$(printf '%s\n' "$request" | nc -U "$socket" | head -n 1)
if jq -e '.error' >/dev/null 2>&1 <<<"$response"; then
  jq -r '.error.message // .error' <<<"$response" >&2
  exit 1
fi
