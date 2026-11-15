# Awake

Tiny native macOS menu bar app that keeps your Mac awake.

- Click the cup icon to toggle (filled = awake, outline = normal sleep)
- Remembers whether it was on or off and restores it on next launch
- Opens at login (turn off with right-click → Open at Login)
- Right-click for Open at Login and Quit

Needs Xcode Command Line Tools (`xcode-select --install`).

- `./install.sh` builds, installs to `/Applications/Awake.app` and launches it (re-run to update)
- `./build.sh` only builds `Awake.app` in this folder

The app icon art is `Resources/icon-source.png`. To rebuild `Resources/AppIcon.icns` from it:

```sh
mkdir -p /tmp/AppIcon.iconset
swift scripts/make-icon.swift Resources/icon-source.png /tmp/AppIcon.iconset
iconutil -c icns /tmp/AppIcon.iconset -o Resources/AppIcon.icns
```
