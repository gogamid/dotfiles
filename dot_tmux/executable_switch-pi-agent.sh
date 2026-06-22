#!/bin/bash
# Pi-agent switcher — tmux display-menu with self-contained run-shell actions.
# If invoked with --create <pane> <proj> <label> <root>, creates a new pi directly.
# Before showing the newly selected pi, hides any currently visible one.

CUR_OPT="@pi_current"

# --- helper: hide the current pi if it's visible in the active window ---
hide_current() {
    local current_visible
    current_visible=$(tmux show-option -gv "$CUR_OPT" 2>/dev/null)
    [ -z "$current_visible" ] && return 0
    local cur_win my_win
    cur_win=$(tmux display-message -p -t "$current_visible" '#{window_id}' 2>/dev/null)
    my_win=$(tmux display-message -p '#{window_id}' 2>/dev/null)
    [ "$cur_win" != "$my_win" ] && return 0
    tmux break-pane -s "$current_visible" 2>/dev/null
    local new_win
    new_win=$(tmux display-message -p -t "$current_visible" '#{window_id}' 2>/dev/null)
    tmux move-window -s "$new_win" -a 2>/dev/null
}

# --- direct creation mode (called from menu action) ---
if [ "$1" = "--create" ]; then
    current_pane="$2"
    proj="$3"
    label="$4"
    root="$5"

    hide_current

    suffix=$(date +%s)
    unique_name="${label}_${suffix}"

    tmux new-window -d -n "$unique_name" -c "$root" pi
    sleep 0.3
    pane=$(tmux list-panes -t "$unique_name" -F '#{pane_id}' | head -1)

    if [ -z "$pane" ]; then
        tmux display-message "pi($proj): failed"
        exit 1
    fi

    count=$(tmux show-option -gv "@pi_count_${proj}" 2>/dev/null || echo "0")
    tmux set-option -g "@pi_pane_${proj}_${count}" "$pane"
    tmux set-option -g "@pi_count_${proj}" $((count + 1))
    tmux set-option -g "$CUR_OPT" "$pane"
    tmux join-pane -h -b -l 20% -s "$pane" -t "$current_pane"
    exit 0
fi

# --- menu mode ---
current_pane=$(tmux display-message -p '#{pane_id}')

# Current project
path=$(tmux display-message -p '#{pane_current_path}')
root=$(cd "$path" && git rev-parse --show-toplevel 2>/dev/null) || root="$path"
proj=$(basename "$root")
label=$(printf "%.10s" "$proj")

script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# --- check if any existing panes (to decide direct creation vs menu) ---
has_items=0
while IFS=' ' read -r opt val; do
    val="${val#\"}"; val="${val%\"}"
    [ -z "$val" ] && continue
    if tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$val"; then
        has_items=1
        break
    fi
done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')

if [ "$has_items" -eq 0 ]; then
    # No existing panes — create directly (no menu)
    hide_current
    suffix=$(date +%s)
    unique_name="${label}_${suffix}"
    tmux new-window -d -n "$unique_name" -c "$root" pi
    sleep 0.3
    pane=$(tmux list-panes -t "$unique_name" -F '#{pane_id}' | head -1)
    if [ -z "$pane" ]; then
        tmux display-message "pi($proj): failed"
        exit 1
    fi
    count=$(tmux show-option -gv "@pi_count_${proj}" 2>/dev/null || echo "0")
    tmux set-option -g "@pi_pane_${proj}_${count}" "$pane"
    tmux set-option -g "@pi_count_${proj}" $((count + 1))
    tmux set-option -g "$CUR_OPT" "$pane"
    tmux join-pane -h -b -l 20% -s "$pane" -t "$current_pane"
    exit 0
fi

# --- build menu ---
# "Create new" calls THIS SCRIPT with --create (no #{...} format expansion issues)
# For existing pi: break current pi first (if visible), then join the selected one
# $() inside run-shell is shell command sub, not tmux format, so #{...} stays safe
create_cmd="run-shell '${script_path} --create ${current_pane} ${proj} ${label} ${root}'"

menu_args=()
menu_args+=("+  new ${label}")   ; menu_args+=("n") ; menu_args+=("$create_cmd")
menu_args+=("")                    ; menu_args+=("") ; menu_args+=("")  # separator

while IFS=' ' read -r opt val; do
    val="${val#\"}"; val="${val%\"}"
    [ -z "$val" ] && continue
    if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$val"; then
        tmux set-option -gu "$opt" 2>/dev/null
        continue
    fi
    stripped="${opt#@pi_pane_}"
    disp_proj="${stripped%_*}"
    idx="${stripped##*_}"
    # break-pane silently fails if @pi_current is already hidden, then join new one
    select_cmd="run-shell 'tmux break-pane -s \$(tmux show-option -gv ${CUR_OPT} 2>/dev/null) 2>/dev/null; tmux set-option -g ${CUR_OPT} ${val} && tmux join-pane -h -b -l 20% -s ${val} -t ${current_pane}'"
    menu_args+=("${disp_proj} #${idx}") ; menu_args+=("") ; menu_args+=("$select_cmd")
done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')

# Show menu
tmux display-menu -T " Pi Agent " "${menu_args[@]}"
