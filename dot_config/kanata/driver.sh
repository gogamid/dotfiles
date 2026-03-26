#!/bin/bash
set -e

case "$1" in
install)
	REPO="pqrs-org/Karabiner-DriverKit-VirtualHIDDevice"
	API_URL="https://api.github.com/repos/${REPO}/releases/latest"

	echo "Fetching latest Karabiner-DriverKit-VirtualHIDDevice release..."

	PKG_URL=$(curl --silent "$API_URL" |
		grep "browser_download_url" |
		grep "\.pkg" |
		cut -d '"' -f 4)

	if [ -z "$PKG_URL" ]; then
		echo "Error: Could not find .pkg download URL." >&2
		exit 1
	fi

	echo "Downloading from: $PKG_URL"
	curl -L "$PKG_URL" -o /tmp/Karabiner-DriverKit-VirtualHIDDevice.pkg

	echo "Installing..."
	sudo installer -pkg /tmp/Karabiner-DriverKit-VirtualHIDDevice.pkg -target /

	echo "Requesting driver permissions."
	/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate

	rm /tmp/Karabiner-DriverKit-VirtualHIDDevice.pkg
	echo "Done."
	;;

uninstall)
	echo "Uninstalling..."

	bash '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/deactivate_driver.sh'
	sudo bash '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/remove_files.sh'
	sudo killall Karabiner-VirtualHIDDevice-Daemon

	echo "Done."
	;;

*)
	echo "Usage: $0 [install|uninstall]"
	exit 1
	;;
esac
