#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf Awake.app
mkdir -p Awake.app/Contents/MacOS
swiftc -O Sources/main.swift -o Awake.app/Contents/MacOS/Awake
cp Info.plist Awake.app/Contents/Info.plist
mkdir -p Awake.app/Contents/Resources
cp Resources/AppIcon.icns Awake.app/Contents/Resources/
codesign --force --sign - Awake.app
echo "Built $(pwd)/Awake.app"
