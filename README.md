<p align="center">
  <img src="docs/icon.png" width="160" alt="Awake icon: a pixel-art coffee cup">
</p>

<h1 align="center">Awake</h1>

<p align="center">A tiny native macOS menu bar app that keeps your Mac awake.<br>One click, or none: it also wakes up by itself while music plays or Claude works.<br>No windows, no Dock icon, ~450 lines of Swift.</p>

## Features

- **One-click toggle** in the menu bar: a filled cup means awake, an outlined cup means normal sleep
- **Turns itself on while you listen or Claude works**: whenever audio is playing (Spotify, Apple Music, YouTube, a call) or a Claude session is working (Claude Code in a terminal, T3 Code, Hooman Studio, or a Cowork task in the Claude app), Awake keeps the Mac and screen awake and shows a steaming cup. It lets go 10 minutes after Claude goes quiet, or as soon as the audio stops. Turn either off from the right-click menu
- **Remembers** whether it was on or off and restores it the next time it starts
- **Opens at login**; turn that off with right-click → *Open at Login*
- **Updates itself**: checks GitHub for a new release once a day, installs it and relaunches with your on/off setting kept. Turn that off with right-click → *Update Automatically*
- **Featherweight**: a 221 KB native app (a 79 KB download) using about 12 MB of RAM, with no Electron and no dependencies
- Uses the same macOS power API as `caffeinate`, so the Mac and the display stay awake while it's on, and quitting always lets the Mac sleep again

## Awake vs. KeepingYouAwake vs. Caffeine

All three keep your Mac awake from the menu bar. Here is what each one costs you:

| | **Awake 1.2** | KeepingYouAwake 1.6.8 | Caffeine 1.1.4 |
| --- | --- | --- | --- |
| Download | **79 KB** | 4.5 MB (57× larger) | 828 KB (11× larger) |
| Size on disk | **221 KB**, 4 files | 7.2 MB, 310 files (33×) | 776 KB, 21 files (4×) |
| Memory, off | **12 MB** | 13 MB | 16 MB |
| Memory, on | **12 MB** | 13 MB + 2.3 MB helper process | not measured |
| CPU while idle | **0.006%** | 0.006% | 1.4–4.1% |
| CPU wake-ups per second | **0.006** | 0.011 | 10.2 |
| Extra processes | **none** | starts `caffeinate` while on | none |
| Bundled frameworks | **none** (updater built in) | Sparkle updater | none |

**Caffeine** redraws its menu bar icon about 10 times a second, even while it's switched off. That keeps a CPU core waking up all day and shows up in Activity Monitor's *Energy* tab. Awake only draws its icon when you click it.

**KeepingYouAwake** is just as quiet at rest as Awake. It's a 33× larger app, though: it ships an auto-updater framework, and it runs a second process (`caffeinate`) while it's on. Awake calls the macOS power API itself.

<details>
<summary>How these numbers were measured</summary>

On a MacBook with an Apple M4 and 16 GB of RAM, macOS 27.0, on November 15, 2026. Each app came from its official release: the Awake 1.2 DMG and Homebrew's `keepingyouawake` and `caffeine` casks. Awake's memory and CPU were measured on a local build of 1.0.1. Launched side by side, the released 1.0.1 and 1.0.2 apps use the same memory, and a local build of 1.1 matched 1.0.2's memory, CPU and wake-ups. Each app was launched with default settings, left alone for 15 seconds, then watched for 3 minutes.

- **Download / size on disk**: the size of the release file, and the sum of all file sizes inside the `.app`
- **Memory**: `footprint -p <pid>`, the same number Activity Monitor shows as *Memory*
- **CPU and wake-ups**: `top -l 180 -s 1 -pid <pid> -stats cpu,idlew`, averaged over the 3 minutes
- **Helper process**: `pgrep -P <pid>`, with `footprint` again for its memory

`scripts/measure.sh <Awake.dmg>` measures an Awake DMG this way (add `--sizes` for the sizes alone). It runs the app under its own bundle ID, so your installed Awake and its settings are left alone.

The Caffeine CPU range comes from two separate 3-minute runs. Caffeine's *on* state could not be measured: its "activate on launch" setting didn't turn it on in this test.

</details>

## Install

1. Download the **Awake .dmg** from the [latest release](https://github.com/betterCallHex/awake/releases/latest)
2. Open it and drag **Awake** into **Applications**
3. Open Awake from Applications. A cup appears in your menu bar.

<img src="docs/install.png" width="520" alt="Install window: drag Awake into Applications">

Works on macOS 13 Ventura or later, on Apple Silicon and Intel Macs.

### Homebrew

```sh
brew trust --tap betterCallHex/tap   # Homebrew 7+ only loads taps you trust
brew install --cask betterCallHex/tap/awake
```

**First launch (DMG or Homebrew):** Awake is free and not signed with a paid Apple Developer ID, so macOS will say it *"could not verify Awake"*. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to Awake. You only need to do this once.

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

`install.sh` builds the app, installs it to `/Applications/Awake.app` and launches it. Run it again to update: apps built from source don't update themselves, so a release never overwrites your build.
`./build.sh` only builds `Awake.app` in the project folder, as a development copy: it runs under the bundle ID `local.awake.dev`, with its own settings, and never adds itself to your login items, so it can run beside your installed Awake. `scripts/test.sh` runs the tests.

## Usage

| Action | Result |
| --- | --- |
| Click the cup | Toggle *always awake* on/off |
| Right-click (or Ctrl-click) | Menu: *Stay Awake While Audio Plays*, *Stay Awake While Claude Works*, *Open at Login*, *Update Automatically*, *Check for Updates…*, *Quit Awake* |

| Icon | Meaning |
| --- | --- |
| Outlined cup | Normal sleep |
| Steaming cup | Awake for now, because audio is playing or Claude is working |
| Cup on a saucer | Always awake, until you click it again |

Awake notices audio through the same macOS signal that tells the system a speaker is in use, and Claude through the session transcripts Claude writes to `~/.claude/projects` (and the Claude app's Cowork folder) while it works. Both are event-driven, so Awake still never polls. A chat in the Claude app that isn't a Cowork task writes nothing to disk, so it doesn't count.

Awake only blocks idle sleep. Closing the lid or choosing Apple menu → Sleep still puts the Mac to sleep.

## App icon

The icon is 16×16 pixel art drawn in code by [`scripts/make-icon.swift`](scripts/make-icon.swift). To change it, edit the `art` grid there (each `#` is one pixel), then rebuild `Resources/AppIcon.icns`. This needs [pngquant](https://pngquant.org) and [oxipng](https://github.com/oxipng/oxipng) (`brew install pngquant oxipng`). `make-icon.swift` draws each pixel size once, and `scripts/pack-icns.swift` stores the optimised PNGs as they are, where `iconutil` would re-encode them at twice the size:

```sh
mkdir -p /tmp/AppIcon
swift scripts/make-icon.swift /tmp/AppIcon
pngquant --quality 95-100 --speed 1 --force --ext .png /tmp/AppIcon/*.png
oxipng -o max -Z --strip all /tmp/AppIcon/*.png
swift scripts/pack-icns.swift /tmp/AppIcon Resources/AppIcon.icns
sips -z 512 512 /tmp/AppIcon/1024.png --out docs/icon.png
```

## Releasing

Publish a release on GitHub with a `v<version>` tag (for example `gh release create v1.1 --generate-notes`). The [Release workflow](.github/workflows/release.yml) then:

1. Stamps `<version>` into `Info.plist` and runs `./release.sh`, which builds a universal, self-updating app (`./build.sh --self-updating`) and packages `dist/Awake-<version>.dmg` with [dmgbuild](https://github.com/dmgbuild/dmgbuild)
2. Attaches the DMG to the release
3. Updates `version` and `sha256` in `Casks/awake.rb` in [betterCallHex/homebrew-tap](https://github.com/betterCallHex/homebrew-tap), pushing with the `TAP_DEPLOY_KEY` deploy key
4. Opens a pull request that sets the README's download and size-on-disk numbers to the new DMG's

Installed copies pick the release up within a day: [`Sources/Updater.swift`](Sources/Updater.swift) asks the GitHub API for the latest release, downloads its `.dmg`, checks that the app inside is Awake at that version with an intact code signature, swaps it in place and relaunches. Every release needs a `v<version>` tag and a `.dmg` asset for this to work.

To build a DMG locally, run `./release.sh` (needs [uv](https://docs.astral.sh/uv/)).

The DMG window background is pixel art drawn by [`scripts/make-dmg-background.swift`](scripts/make-dmg-background.swift):

```sh
swift scripts/make-dmg-background.swift Resources/dmg-background.png 1
swift scripts/make-dmg-background.swift Resources/dmg-background@2x.png 2
oxipng -o max -Z --strip all Resources/dmg-background*.png
```
