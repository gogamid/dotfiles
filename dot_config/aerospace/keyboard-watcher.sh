#!/bin/sh
BINARY="$HOME/.config/aerospace/keyboard-watcher"
SOURCE="$HOME/.config/aerospace/keyboard-watcher.swift"

if [ ! -f "$BINARY" ] || [ "$SOURCE" -nt "$BINARY" ]; then
	swiftc "$SOURCE" -o "$BINARY" -framework IOKit || exit 1
fi

exec "$BINARY"
