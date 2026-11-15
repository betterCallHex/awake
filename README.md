<p align="center">
  <img src="docs/icon.png" width="160" alt="Awake icon: a pixel-art coffee cup">
</p>

<h1 align="center">Awake</h1>

<p align="center">A tiny native macOS menu bar app that keeps your Mac awake.<br>One click. No windows, no Dock icon, ~70 lines of Swift.</p>

## Features

- **One-click toggle** in the menu bar: a filled cup means awake, an outlined cup means normal sleep
- **Remembers** whether it was on or off and restores it the next time it starts
- **Opens at login**; turn that off with right-click → *Open at Login*
- **Featherweight**: a 68 KB native app using about 11 MB of RAM, with no Electron and no dependencies
- Uses the same macOS power API as `caffeinate`, so the Mac and the display stay awake while it's on, and quitting always lets the Mac sleep again

## Install

Requires macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/betterCallHex/awake.git
cd awake
./install.sh
```

`install.sh` builds the app, installs it to `/Applications/Awake.app` and launches it. Run it again to update.
`./build.sh` only builds `Awake.app` in the project folder.

## Usage

| Action | Result |
| --- | --- |
| Click the cup | Toggle awake on/off |
| Right-click (or Ctrl-click) | Menu: *Open at Login*, *Quit Awake* |

Awake only blocks idle sleep. Closing the lid or choosing Apple menu → Sleep still puts the Mac to sleep.

## App icon

The icon is 16×16 pixel art drawn in code by [`scripts/make-icon.swift`](scripts/make-icon.swift). To change it, edit the `art` grid there (each `#` is one pixel), then rebuild `Resources/AppIcon.icns`:

```sh
mkdir -p /tmp/AppIcon.iconset
swift scripts/make-icon.swift /tmp/AppIcon.iconset
iconutil -c icns /tmp/AppIcon.iconset -o Resources/AppIcon.icns
sips -z 512 512 /tmp/AppIcon.iconset/icon_512x512@2x.png --out docs/icon.png
```
