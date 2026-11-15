#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf Awake.app
mkdir -p Awake.app/Contents/MacOS Awake.app/Contents/Resources
for arch in arm64 x86_64; do
    swiftc -O -target "$arch-apple-macos13.0" Sources/main.swift -o "/tmp/Awake-$arch"
done
lipo -create /tmp/Awake-arm64 /tmp/Awake-x86_64 -output Awake.app/Contents/MacOS/Awake
strip -x Awake.app/Contents/MacOS/Awake
rm /tmp/Awake-arm64 /tmp/Awake-x86_64
cp Info.plist Awake.app/Contents/Info.plist
cp Resources/AppIcon.icns Awake.app/Contents/Resources/
codesign --force --sign - Awake.app
echo "Built $(pwd)/Awake.app"
