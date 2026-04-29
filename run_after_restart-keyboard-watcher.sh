#!/bin/sh
# Ensure keyboard-watcher daemon is running.
# Restarts if already loaded, bootstraps if not.
launchctl kickstart -k gui/$(id -u)/gamidli.keyboard-watcher 2>/dev/null ||
	launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/gamidli.keyboard-watcher.plist 2>/dev/null || true
