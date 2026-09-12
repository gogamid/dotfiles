#!/usr/bin/env bash
set -euo pipefail

## system-update LaunchAgent bootstrap
domain="gui/$(id -u)"
plist="$HOME/Library/LaunchAgents/com.system-update.plist"
label="com.system-update"

if [[ ! -f "$plist" ]]; then
	echo "launchd: no com.system-update plist, skipping bootstrap" >&2
else
	if launchctl print "$domain/$label" >/dev/null 2>&1; then
		launchctl bootout "$domain/$label" 2>/dev/null || true
	fi
	launchctl bootstrap "$domain" "$plist" || echo "!! launchctl bootstrap failed" >&2
	echo "launchd: loaded $label"
fi

## work-machine tooling setup (Go tools + Neovim Mason)
repo="$HOME/work/lidl-wawi"
if [[ ! -d "$repo" ]]; then
	echo "setup-work-tools: lidl-wawi repo not present on this machine; skipping" >&2
	exit 0
fi

echo ">> make setup: syncing lidl-wawi Go tools (buf, protoc-gen-*, golangci-lint)"
(cd "$repo" && make setup) || echo "!! make setup failed (see above)" >&2

if command -v nvim >/dev/null 2>&1; then
	echo ">> updating Neovim Mason packages"
	nvim --headless "+MasonUpdate" +qa || echo "!! MasonUpdate failed (see above)" >&2
else
	echo ">> nvim not found on PATH; skipping Mason update" >&2
fi

echo ">> setup-work-tools done"
