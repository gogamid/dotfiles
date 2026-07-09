#!/bin/bash
# Pi-agent switcher — tmux display-menu with self-contained run-shell actions.
# If invoked with --create <pane> <proj> <label> <root>, creates a new pi directly.
# Pane width read from @pi_pane_width (default 50). Indices reused (dead panes cleaned).
# Uses pane_dead check to handle processes that died during sleep.

CUR_OPT="@pi_current"
PI_WIDTH_OPT="@pi_pane_width"
PI_WIDTH=$(tmux show-option -gv "$PI_WIDTH_OPT" 2>/dev/null || echo 50)

# --- helpers ---
pane_is_alive() {
    local dead
    dead=$(tmux display-message -p -t "$1" '#{pane_dead}' 2>/dev/null)
    [ "$dead" = "0" ] 2>/dev/null
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

hide_current() {
    local dir
    dir="$(cd "$(dirname "$0")" && pwd)"
    "${dir}/toggle-pi-agent.sh" --hide 2>/dev/null
}

idx_to_letter() {
    local oct
    printf -v oct '%03o' $((97 + $1))
    printf "\\$oct"
}

# --- --create mode (called from menu action) ---
if [ "$1" = "--create" ]; then
    current_pane="$2"; proj="$3"; label="$4"; root="$5"
    hide_current
    suffix=$(date +%s)
    unique_name="${label}_${suffix}"
    tmux new-window -d -n "$unique_name" -c "$root" pi
    sleep 0.3
    pane=$(tmux list-panes -t "$unique_name" -F '#{pane_id}' | head -1)
    [ -z "$pane" ] && tmux display-message "pi($proj): failed" && exit 1
    idx=$(find_free_idx "$proj")
    tmux set-option -g "@pi_pane_${proj}_${idx}" "$pane"
    tmux set-option -g "$CUR_OPT" "$pane"
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pane" -t "$current_pane"
    exit 0
fi

# --- menu mode ---
current_pane=$(tmux display-message -p '#{pane_id}')
path=$(tmux display-message -p '#{pane_current_path}')
root=$(cd "$path" && git rev-parse --show-toplevel 2>/dev/null) || root="$path"
proj=$(basename "$root")
label=$(printf "%.10s" "$proj")
script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# --- check if any existing panes ---
has_items=0
while IFS=' ' read -r opt val; do
    val="${val#\"}"; val="${val%\"}"
    [ -z "$val" ] && continue
    if tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$val" && pane_is_alive "$val"; then
        has_items=1; break
    elif ! pane_is_alive "$val"; then
        tmux set-option -gu "$opt" 2>/dev/null
    fi
done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')

if [ "$has_items" -eq 0 ]; then
    hide_current
    suffix=$(date +%s); unique_name="${label}_${suffix}"
    tmux new-window -d -n "$unique_name" -c "$root" pi
    sleep 0.3
    pane=$(tmux list-panes -t "$unique_name" -F '#{pane_id}' | head -1)
    [ -z "$pane" ] && tmux display-message "pi($proj): failed" && exit 1
    idx=$(find_free_idx "$proj")
    tmux set-option -g "@pi_pane_${proj}_${idx}" "$pane"
    tmux set-option -g "$CUR_OPT" "$pane"
    tmux join-pane -h -b -l ${PI_WIDTH}% -s "$pane" -t "$current_pane"
    exit 0
fi

# --- build menu ---
create_cmd="run-shell '${script_path} --create ${current_pane} ${proj} ${label} ${root}'"

width_cmd="run-shell 'CUR=\$(tmux show-option -gv @pi_pane_width 2>/dev/null || echo 50); tmux display-menu -T \" Pane Width ${PI_WIDTH}% \" \
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
menu_args+=("")                    ; menu_args+=("") ; menu_args+=("")
menu_args+=("> Set pane width ${PI_WIDTH}%") ; menu_args+=("w") ; menu_args+=("$width_cmd")
menu_args+=("")                    ; menu_args+=("") ; menu_args+=("")

# Existing panes — check pane_dead, clean up dead ones, show alive ones
key_idx=1
while IFS=' ' read -r opt val; do
    val="${val#\"}"; val="${val%\"}"
    [ -z "$val" ] && continue
    if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$val"; then
        tmux set-option -gu "$opt" 2>/dev/null; continue
    fi
    if ! pane_is_alive "$val"; then
        tmux set-option -gu "$opt" 2>/dev/null; continue
    fi
    stripped="${opt#@pi_pane_}"; dp="${stripped%_*}"; idx="${stripped##*_}"
    letter=$(idx_to_letter "$idx")
    scmd="run-shell '~/.tmux/toggle-pi-agent.sh --hide 2>/dev/null; tmux set-option -g ${CUR_OPT} ${val} && tmux join-pane -h -b -l \$(tmux show-option -gv ${PI_WIDTH_OPT} 2>/dev/null || echo 50)% -s ${val} -t ${current_pane}'"
    k=""; [ "$key_idx" -le 9 ] && k="$key_idx"
    menu_args+=("${dp} #${letter}") ; menu_args+=("$k") ; menu_args+=("$scmd")
    ((key_idx++))
done < <(tmux show-options -g 2>/dev/null | grep '^@pi_pane_')

tmux display-menu -T " Pi Agent " "${menu_args[@]}"
