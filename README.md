<p align="center">
  <img src="docs/icon.png" width="160" alt="Awake icon: a pixel-art coffee cup">
</p>

<h1 align="center">Awake</h1>

<p align="center">A tiny native macOS menu bar app that keeps your Mac awake.<br>One click. No windows, no Dock icon, ~70 lines of Swift.</p>

## Features

- **One-click toggle** in the menu bar: a filled cup means awake, an outlined cup means normal sleep
- **Remembers** whether it was on or off and restores it the next time it starts
- **Opens at login**; turn that off with right-click → *Open at Login*
- **Featherweight**: a 150 KB native app (a 62 KB download) using about 11 MB of RAM, with no Electron and no dependencies
- Uses the same macOS power API as `caffeinate`, so the Mac and the display stay awake while it's on, and quitting always lets the Mac sleep again

## Install

1. Download the **Awake .dmg** from the [latest release](https://github.com/betterCallHex/awake/releases/latest)
2. Open it and drag **Awake** into **Applications**
3. Open Awake from Applications. A cup appears in your menu bar.

<img src="docs/install.png" width="520" alt="Install window: drag Awake into Applications">

Works on macOS 13 Ventura or later, on Apple Silicon and Intel Macs.

**First launch:** Awake is free and not signed with a paid Apple Developer ID, so macOS will say it *"could not verify Awake"*. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to Awake. You only need to do this once.

Prefer the Terminal? This does the same thing:

```sh
xattr -dr com.apple.quarantine /Applications/Awake.app && open /Applications/Awake.app
```

### Build from source

Requires the Xcode Command Line Tools (`xcode-select --install`).

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

The icon is 16×16 pixel art drawn in code by [`scripts/make-icon.swift`](scripts/make-icon.swift). To change it, edit the `art` grid there (each `#` is one pixel), then rebuild `Resources/AppIcon.icns`. This needs [oxipng](https://github.com/oxipng/oxipng) (`brew install oxipng`); `scripts/pack-icns.swift` stores the optimised PNGs as they are, where `iconutil` would re-encode them at twice the size:

```sh
mkdir -p /tmp/AppIcon.iconset
swift scripts/make-icon.swift /tmp/AppIcon.iconset
oxipng -o max --strip safe /tmp/AppIcon.iconset/*.png
swift scripts/pack-icns.swift /tmp/AppIcon.iconset Resources/AppIcon.icns
sips -z 512 512 /tmp/AppIcon.iconset/icon_512x512@2x.png --out docs/icon.png
```

## Releasing

1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in `Info.plist`
2. `./release.sh` builds a universal app and packages `dist/Awake-<version>.dmg` with [dmgbuild](https://github.com/dmgbuild/dmgbuild) (run through `uvx`, so you need [uv](https://docs.astral.sh/uv/))
3. `gh release create v<version> dist/Awake-<version>.dmg`

The DMG window background is pixel art drawn by [`scripts/make-dmg-background.swift`](scripts/make-dmg-background.swift):

```sh
swift scripts/make-dmg-background.swift Resources/dmg-background.png 1
swift scripts/make-dmg-background.swift Resources/dmg-background@2x.png 2
oxipng -o max --strip safe Resources/dmg-background*.png
```
