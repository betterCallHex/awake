#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf Awake.app
mkdir -p Awake.app/Contents/MacOS Awake.app/Contents/Resources
swiftc -O -Xlinker -no_data_const -target arm64-apple-macos13.0 Sources/*.swift -o /tmp/Awake-arm64 &
arm64=$!
swiftc -O -Xlinker -no_data_const -target x86_64-apple-macos13.0 Sources/*.swift -o /tmp/Awake-x86_64 &
x86_64=$!
wait $arm64
wait $x86_64
lipo -create /tmp/Awake-arm64 /tmp/Awake-x86_64 -output Awake.app/Contents/MacOS/Awake
strip -x Awake.app/Contents/MacOS/Awake
plutil -convert binary1 -o Awake.app/Contents/Info.plist Info.plist
if [ "$1" = "--self-updating" ]; then
  plutil -insert AwakeSelfUpdating -bool YES Awake.app/Contents/Info.plist
fi
cp Resources/AppIcon.icns Awake.app/Contents/Resources/
codesign --force --sign - Awake.app
lipo Awake.app/Contents/MacOS/Awake -thin arm64 -output /tmp/Awake-arm64
lipo Awake.app/Contents/MacOS/Awake -thin x86_64 -output /tmp/Awake-x86_64
lipo -create /tmp/Awake-arm64 /tmp/Awake-x86_64 -output Awake.app/Contents/MacOS/Awake
rm /tmp/Awake-arm64 /tmp/Awake-x86_64
codesign --verify --strict Awake.app
echo "Built $(pwd)/Awake.app"
