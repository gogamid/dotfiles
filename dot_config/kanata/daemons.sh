#!/bin/bash

DOTFILES_LAUNCH_DAEMONS="$HOME/.local/share/chezmoi/dot_config/kanata"
LAUNCH_DAEMONS="/Library/LaunchDaemons"

shopt -s nullglob
PLISTS=("$DOTFILES_LAUNCH_DAEMONS"/*.plist)

if [[ ${#PLISTS[@]} -eq 0 ]]; then
	echo "ERROR: No .plist files found in $DOTFILES_LAUNCH_DAEMONS"
	exit 1
fi

case "$1" in
install)
	for SRC in "${PLISTS[@]}"; do
		FILENAME=$(basename "$SRC")
		LABEL="${FILENAME%.plist}"
		DEST="$LAUNCH_DAEMONS/$FILENAME"

		sudo cp "$SRC" "$DEST" || {
			echo "ERROR: Failed to copy $FILENAME"
			exit 1
		}
		sudo chown root:wheel "$DEST"
		sudo launchctl enable "system/$LABEL" || echo "WARN: enable failed for $LABEL"
		sudo launchctl bootstrap system "$DEST" || echo "WARN: bootstrap failed for $LABEL"
		sudo launchctl start "$LABEL" || echo "WARN: start failed for $LABEL"
	done
	echo -e "\033[1;33m!! ADDITIONAL SETUP REQUIRED !!"
	echo 'Settings > Keyboard > Keyboard Shortcuts... > Modifier Keys, select keyboard "Karabiner DriverKit VirtualHIDKeyboard x.x.x"'
	echo 'Settings > Privacy & Security > Input Monitoring > click "+" > Press keys SHIFT + COMMAND + G > type "/opt/homebrew/bin/kanata" > Open'
	echo 'Settings > Privacy & Security > Accessibility > click "+" > Press keys SHIFT + COMMAND + G > type "/opt/homebrew/bin/kanata" > Open'
	;;
uninstall)
	for SRC in "${PLISTS[@]}"; do
		FILENAME=$(basename "$SRC")
		LABEL="${FILENAME%.plist}"
		DEST="$LAUNCH_DAEMONS/$FILENAME"

		[[ ! -f "$DEST" ]] && echo "WARN: $DEST not found, skipping" && continue

		sudo launchctl stop "$LABEL"
		sudo launchctl disable "system/$LABEL" || echo "WARN: disable failed for $LABEL"
		sudo launchctl bootout system "$DEST" || echo "WARN: bootout failed for $LABEL"
		sudo rm "$DEST" || echo "ERROR: removal failed for $DEST"
	done
	;;
*)
	echo "Usage: $0 [install|uninstall]"
	exit 1
	;;
esac
