#!/bin/bash
# Pi-agent switcher — tmux display-menu with self-contained run-shell actions.
# If invoked with --create <pane> <proj> <label> <root>, creates a new pi directly.
# Before showing the newly selected pi, hides any currently visible one.
# Pane width is read from @pi_pane_width (default 20). Set via the menu.

CUR_OPT="@pi_current"
PI_WIDTH_OPT="@pi_pane_width"

PI_WIDTH=$(tmux show-option -gv "$PI_WIDTH_OPT" 2>/dev/null || echo 20)

# --- helper: hide the current pi if visible (delegates to toggle --hide to avoid break-pane crash) ---
hide_current() {
    local dir
    dir="$(cd "$(dirname "$0")" && pwd)"
    "${dir}/toggle-pi-agent.sh" --hide 2>/dev/null
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
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pane" -t "$current_pane"
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
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pane" -t "$current_pane"
    exit 0
fi

# --- build menu ---

# "Create new" calls THIS SCRIPT (no #{...} issues)
create_cmd="run-shell '${script_path} --create ${current_pane} ${proj} ${label} ${root}'"

# "Set pane width" — opens a submenu of presets + custom prompt
width_cmd="run-shell 'CUR=\$(tmux show-option -gv @pi_pane_width 2>/dev/null || echo 20); tmux display-menu -T \" Pane Width ${PI_WIDTH}% \" \
    \"15%\"   \"1\" \"set-option -g @pi_pane_width 15\" \
    \"20%\"   \"2\" \"set-option -g @pi_pane_width 20\" \
    \"25%\"   \"3\" \"set-option -g @pi_pane_width 25\" \
    \"30%\"   \"4\" \"set-option -g @pi_pane_width 30\" \
    \"40%\"   \"5\" \"set-option -g @pi_pane_width 40\" \
    \"50%\"   \"6\" \"set-option -g @pi_pane_width 50\" \
    \"\" \"\" \"\" \
    \"Custom...\" \"c\" \"command-prompt -p \\\"Width %:\\\" \\\"set-option -g @pi_pane_width %%\\\"\"'"

menu_args=()
menu_args+=("+  new ${label}")   ; menu_args+=("n") ; menu_args+=("$create_cmd")
menu_args+=("")                    ; menu_args+=("") ; menu_args+=("")  # separator
menu_args+=("> Set pane width ${PI_WIDTH}%") ; menu_args+=("w") ; menu_args+=("$width_cmd")
menu_args+=("")                    ; menu_args+=("") ; menu_args+=("")  # separator

# For existing pi panes: read width at runtime via shell command substitution
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
    # break-pane @pi_current first (silent if hidden), then join selected with dynamic width
    select_cmd="run-shell '~/.tmux/toggle-pi-agent.sh --hide 2>/dev/null; tmux set-option -g ${CUR_OPT} ${val} && tmux join-pane -h -b -l \$(tmux show-option -gv ${PI_WIDTH_OPT} 2>/dev/null || echo 50)% -s ${val} -t ${current_pane}'"
    menu_args+=("${disp_proj} #${idx}") ; menu_args+=("") ; menu_args+=("$select_cmd")
done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')

# Show menu
tmux display-menu -T " Pi Agent " "${menu_args[@]}"
