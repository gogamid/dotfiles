#!/bin/bash
# Fullscreen toggle for pi agent pane.
# C-o: first press  → show pi full screen (own window)
#      second press → hide pi, return to origin window
#
# Tracks origin via @pi_fs_origin option. Validates stale origins
# to stay correct when C-\ is used between C-o calls.
#
# Supports multiple pi agents per project via @pi_pane_<project>_<N>.

CUR_OPT="@pi_current"
FS_ORIGIN_OPT="@pi_fs_origin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOGGLE_SCRIPT="${SCRIPT_DIR}/toggle-pi-agent.sh"

# --- helpers ---

pane_is_alive() {
    local dead
    dead=$(tmux display-message -p -t "$1" '#{pane_dead}' 2>/dev/null)
    [ "$dead" = "0" ] 2>/dev/null
}

hide_current_pi() {
    "$TOGGLE_SCRIPT" --hide 2>/dev/null
}

get_project_label() {
    local path dir proj
    path=$(tmux display-message -p '#{pane_current_path}')
    dir=$(cd "$path" && git rev-parse --show-toplevel 2>/dev/null) || dir="$path"
    proj=$(basename "$dir")
    printf "%.10s" "$proj"
}

find_free_idx() {
    local proj="$1" idx=0
    while : ; do
        local val
        val=$(tmux show-option -gv "@pi_pane_${proj}_${idx}" 2>/dev/null)
        [ -z "$val" ] && echo "$idx" && return 0
        val="${val#\"}"; val="${val%\"}"
        if pane_is_alive "$val"; then
            idx=$((idx + 1))
        else
            tmux set-option -gu "@pi_pane_${proj}_${idx}" 2>/dev/null
            echo "$idx" && return 0
        fi
    done
}

create_pi() {
    local path dir proj label pane idx
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

    idx=$(find_free_idx "$proj")
    tmux set-option -g "@pi_pane_${proj}_${idx}" "$pane"
    tmux set-option -g "$CUR_OPT" "$pane"
    echo "$pane"
}

# --- main ---

current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')

pi_pane=$(tmux show-option -gv "$CUR_OPT" 2>/dev/null)
fs_origin=$(tmux show-option -gv "$FS_ORIGIN_OPT" 2>/dev/null)

# Validate pi pane
if [ -n "$pi_pane" ]; then
    if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$pi_pane"; then
        pi_pane=""
        tmux set-option -gu "$CUR_OPT" 2>/dev/null
    elif ! pane_is_alive "$pi_pane"; then
        pi_pane=""
        tmux set-option -gu "$CUR_OPT" 2>/dev/null
    fi
fi

# Validate fs_origin — clear if window gone or same as current (stale)
if [ -n "$fs_origin" ]; then
    if ! tmux list-windows -F '#{window_id}' 2>/dev/null | grep -qxF "$fs_origin"; then
        fs_origin=""
        tmux set-option -gu "$FS_ORIGIN_OPT" 2>/dev/null
    elif [ "$fs_origin" = "$current_window" ]; then
        fs_origin=""
        tmux set-option -gu "$FS_ORIGIN_OPT" 2>/dev/null
    fi
fi

# Create pi if none exists
if [ -z "$pi_pane" ]; then
    pi_pane=$(create_pi)
    tmux set-option -g "$FS_ORIGIN_OPT" "$current_window"
    pi_window=$(tmux display-message -p -t "$pi_pane" '#{window_id}' 2>/dev/null)
    tmux select-window -t "$pi_window"
    exit 0
fi

pi_window=$(tmux display-message -p -t "$pi_pane" '#{window_id}' 2>/dev/null)

if [ "$pi_window" = "$current_window" ] && [ -n "$fs_origin" ]; then
    # === FULLSCREEN MODE: hide pi and return to origin ===
    hide_current_pi
    tmux select-window -t "$fs_origin"
    tmux set-option -gu "$FS_ORIGIN_OPT" 2>/dev/null

elif [ "$pi_window" = "$current_window" ]; then
    # === PI IS A SPLIT in current window → break to own window ===
    label=$(get_project_label)
    tmux set-option -g "$FS_ORIGIN_OPT" "$current_window"
    new_win=$(tmux break-pane -s "$pi_pane" -P -F '#{window_id}' -n "$label" 2>/dev/null)
    if [ -n "$new_win" ]; then
        tmux select-window -t "$new_win"
    fi

elif [ -n "$pi_window" ]; then
    # === PI IN ANOTHER WINDOW (hidden in shared __ph__ or stray) ===
    # Break to its own window so fullscreen always shows only pi
    tmux set-option -g "$FS_ORIGIN_OPT" "$current_window"
    label=$(get_project_label)
    new_win=$(tmux break-pane -s "$pi_pane" -P -F '#{window_id}' -n "$label" 2>/dev/null)
    if [ -n "$new_win" ]; then
        tmux select-window -t "$new_win"
    fi
fi
