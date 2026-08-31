#!/usr/bin/env bash
set -euo pipefail

domain="gui/$(id -u)"
plist="$HOME/Library/LaunchAgents/com.system-update.plist"
label="com.system-update"

[[ -f "$plist" ]] || exit 0

if launchctl print "$domain/$label" >/dev/null 2>&1; then
	launchctl bootout "$domain/$label" 2>/dev/null || true
fi

launchctl bootstrap "$domain" "$plist"
echo "launchd: loaded $label"