#!/bin/sh
set -e
usage="usage: scripts/measure.sh [--sizes] <Awake.dmg>"
sizes_only=false
if [ "$1" = "--sizes" ]; then
  sizes_only=true
  shift
fi
dmg=${1:?$usage}
domain=local.awake.measure
work=$(mktemp -d)
pid=

cleanup() {
  [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  hdiutil detach "$work/volume" -quiet 2>/dev/null || true
  defaults delete "$domain" 2>/dev/null || true
  rm -f "$HOME/Library/Preferences/$domain.plist"
  rm -rf "$work"
}
trap cleanup EXIT

launch() {
  "$work/Awake.app/Contents/MacOS/Awake" >/dev/null 2>&1 &
  pid=$!
  sleep 15
}

footprint_of() {
  footprint -p "$1" | grep -oE 'Footprint: [0-9.]+ [KMG]B' | head -1 | cut -d' ' -f2-
}

stop() {
  kill "$pid"
  wait "$pid" 2>/dev/null || true
  pid=
}

hdiutil attach -nobrowse -readonly -mountpoint "$work/volume" "$dmg" >/dev/null
ditto "$work/volume/Awake.app" "$work/Awake.app"
hdiutil detach "$work/volume" -quiet

echo "version=$(plutil -extract CFBundleShortVersionString raw "$work/Awake.app/Contents/Info.plist")"
echo "download_bytes=$(stat -f %z "$dmg")"
echo "app_bytes=$(find "$work/Awake.app" -type f -exec stat -f %z {} + | awk '{ total += $1 } END { print total }')"
echo "app_files=$(find "$work/Awake.app" -type f | wc -l | tr -d ' ')"
$sizes_only && exit 0

plutil -replace CFBundleIdentifier -string "$domain" "$work/Awake.app/Contents/Info.plist"
xattr -cr "$work/Awake.app"
codesign --force --sign - "$work/Awake.app"
defaults write "$domain" didSetUpOpenAtLogin -bool true
defaults write "$domain" updatesAutomatically -bool false

defaults write "$domain" isAwake -bool false
launch
echo "memory_off=$(footprint_of "$pid")"
top -l 181 -s 1 -pid "$pid" -stats cpu,idlew | awk '
  /^ *[0-9.]+ +[0-9]+ *$/ { if (samples++ == 0) { first_wakeups = $2 } else { cpu += $1; last_wakeups = $2 } }
  END { printf "cpu_percent=%.4f\nwakeups_per_second=%.4f\n", cpu / (samples - 1), (last_wakeups - first_wakeups) / (samples - 1) }'
stop

defaults write "$domain" isAwake -bool true
launch
echo "memory_on=$(footprint_of "$pid")"
stop
