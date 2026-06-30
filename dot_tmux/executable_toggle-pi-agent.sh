#!/bin/bash
# Toggle the "current" pi-agent on/off.
# If invoked with --hide, hides @pi_current silently (for switch menu).
# Creates one for the current project if none exists yet.
# Supports multiple pi agents per project via @pi_pane_<project>_<N> keys.
# Indices are reused (first free slot found, no gaps).

CUR_OPT="@pi_current"
PI_WIDTH_OPT="@pi_pane_width"
PI_WIDTH=$(tmux show-option -gv "$PI_WIDTH_OPT" 2>/dev/null || echo 50)

# --- helpers ---
find_free_idx() {
    local proj="$1" idx=0
    while tmux show-option -gv "@pi_pane_${proj}_${idx}" 2>/dev/null | grep -q .; do
        idx=$((idx + 1))
    done
    echo "$idx"
}

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

# Hide @pi_current safely (join-pane to __ph__ window, avoid tmux break-pane crash)
hide_current_pi() {
    local pane new_win
    pane=$(tmux show-option -gv "$CUR_OPT" 2>/dev/null)
    [ -z "$pane" ] && return 0
    local pw ww
    pw=$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null)
    ww=$(tmux display-message -p '#{window_id}' 2>/dev/null)
    [ "$pw" != "$ww" ] && return 0
    HIDE_LABEL="__ph__"
    HIDE_WIN=$(tmux list-windows -F '#{window_id}:#{window_name}' | grep ":${HIDE_LABEL}$" | cut -d: -f1 | head -1 2>/dev/null)
    if [ -n "$HIDE_WIN" ]; then
        local pc
        pc=$(tmux list-panes -t "$HIDE_WIN" 2>/dev/null | wc -l | tr -d ' ')
        [ "$pc" -eq 0 ] && tmux kill-window -t "$HIDE_WIN" 2>/dev/null && HIDE_WIN=""
    fi
    if [ -z "$HIDE_WIN" ]; then
        HIDE_WIN=$(tmux new-window -d -P -F '#{window_id}' -n "$HIDE_LABEL" 2>/dev/null)
    fi
    tmux join-pane -s "$pane" -t "$HIDE_WIN" 2>/dev/null
    sleep 0.1
    local pc
    pc=$(tmux list-panes -t "$HIDE_WIN" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$pc" -gt 1 ]; then
        local first
        first=$(tmux list-panes -F '#{pane_id}' -t "$HIDE_WIN" 2>/dev/null | head -1)
        [ -n "$first" ] && tmux kill-pane -t "$first" 2>/dev/null
    fi
    tmux move-window -s "$HIDE_WIN" -a 2>/dev/null
}

# --- --hide mode (called from switch menu to avoid break-pane crash) ---
if [ "$1" = "--hide" ]; then
    hide_current_pi
    exit 0
fi

current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')

# --- create new pi for the current project ---
create_and_show() {
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
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pane" -t "$current_pane"
}

# --- main ---
pi_pane=$(tmux show-option -gv "$CUR_OPT" 2>/dev/null)

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
    hide_current_pi
    tmux select-window -t "$current_window"
else
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pi_pane" -t "$current_pane"
fi
