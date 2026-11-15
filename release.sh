#!/bin/sh
set -e
cd "$(dirname "$0")"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
DMG="dist/Awake-$VERSION.dmg"
./build.sh --self-updating
mkdir -p dist
rm -f "$DMG"
uvx dmgbuild -s scripts/dmg-settings.py "Awake" "$DMG"
echo "Created $(pwd)/$DMG"
