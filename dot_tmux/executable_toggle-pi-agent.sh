#!/bin/bash
# Toggle the "current" pi-agent on/off.
# Creates one for the current project if none exists yet.
# Supports multiple pi agents per project via @pi_pane_<project>_<N> keys.

CUR_OPT="@pi_current"

current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')

# --- helper: find project name for a pane ID ---
find_project() {
    local pane_id="$1"
    while IFS=' ' read -r opt val; do
        val="${val#\"}"; val="${val%\"}"
        [ "$val" = "$pane_id" ] || continue
        local remainder="${opt#@pi_pane_}"
        echo "${remainder%_*}"
        return 0
    done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')
    return 1
}

# --- helper: create a new pi for the current project ---
create_and_show() {
    local path dir proj label pane count idx
    path=$(tmux display-message -p '#{pane_current_path}')
    dir=$(cd "$path" && git rev-parse --show-toplevel 2>/dev/null) || dir="$path"
    proj=$(basename "$dir")
    label=$(printf "%.10s" "$proj")

    win_id=$(tmux new-window -d -P -F '#{window_id}' -n "$label" -c "$dir" 'pi')
    sleep 0.3
    pane=$(tmux list-panes -F '#{pane_id}' -t "$win_id" | head -1)
    if [ -z "$pane" ]; then
        tmux display-message "pi($proj): failed"
        exit 1
    fi

    count=$(tmux show-option -gv "@pi_count_${proj}" 2>/dev/null || echo "0")
    idx="${count}"
    tmux set-option -g "@pi_pane_${proj}_${idx}" "$pane"
    tmux set-option -g "@pi_count_${proj}" $((count + 1))
    tmux set-option -g "$CUR_OPT" "$pane"
    tmux join-pane -h -b -l 20% -s "$pane" -t "$current_pane"
}

# --- main ---
pi_pane=$(tmux show-option -gv "$CUR_OPT" 2>/dev/null)

# Verify stored pane still exists
if [ -n "$pi_pane" ]; then
    if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$pi_pane"; then
        pi_pane=""
        tmux set-option -gu "$CUR_OPT" 2>/dev/null
    fi
fi

if [ -z "$pi_pane" ]; then
    create_and_show
    exit 0
fi

# Toggle: show if hidden, hide if shown
pi_win_id=$(tmux display-message -p -t "$pi_pane" '#{window_id}' 2>/dev/null)
if [ "$pi_win_id" = "$current_window" ]; then
    # --- HIDE ---
    tmux break-pane -s "$pi_pane"
    pi_new_win=$(tmux display-message -p -t "$pi_pane" '#{window_id}')
    tmux move-window -s "$pi_new_win" -a 2>/dev/null
    # Rename to project name for the picker
    proj=$(find_project "$pi_pane")
    [ -n "$proj" ] && tmux rename-window "$(printf "%.10s" "$proj")" 2>/dev/null
    tmux select-window -t "$current_window"
else
    # --- SHOW ---
    tmux join-pane -h -b -l 20% -s "$pi_pane" -t "$current_pane"
fi
