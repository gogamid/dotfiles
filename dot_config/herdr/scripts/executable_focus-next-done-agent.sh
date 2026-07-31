#!/bin/bash
set -euo pipefail

snapshot=$(herdr api snapshot)

pane_id=$(jq -r '
  .result.snapshot as $snapshot
  | $snapshot.agents as $agents
  | ($agents | length) as $count
  | if $count == 0 then empty
    else (
      [$agents | to_entries[] | select(.value.pane_id == $snapshot.focused_pane_id) | .key][0] // -1
    ) as $current
    | [
        range(1; $count + 1) as $offset
        | $agents[(($current + $offset) % $count)]
        | select(.agent_status == "done")
      ][0].pane_id // empty
    end
' <<<"$snapshot")

# There is nothing requiring attention.
[ -n "$pane_id" ] || exit 0

socket=$(herdr status server | awk -F': ' '$1 == "socket" { print $2 }')
[ -n "$socket" ] || {
  echo "Could not determine the Herdr server socket" >&2
  exit 1
}

request=$(jq -cn --arg pane_id "$pane_id" '{
  id: "focus-next-done-agent",
  method: "pane.focus",
  params: {pane_id: $pane_id}
}')

response=$(printf '%s\n' "$request" | nc -U "$socket" | head -n 1)
if jq -e '.error' >/dev/null 2>&1 <<<"$response"; then
  jq -r '.error.message // .error' <<<"$response" >&2
  exit 1
fi
