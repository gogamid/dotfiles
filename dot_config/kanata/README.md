- [Reference](https://github.com/jtroo/kanata/discussions/1972)

### Install kanata

```bash
brew install kanata
```

### Install Karabiner-VirtualHIDDevice

install manually pkg from https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases incase fails

```bash
./driver.sh install
```

### Install plist daemons

```bash
./daemons.sh install
```

### Reload after config changes

```bash
sudo launchctl unload /Library/LaunchDaemons/gamidli.kanata.plist && sudo launchctl load /Library/LaunchDaemons/gamidli.kanata.plist
```
