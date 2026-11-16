#!/bin/sh
set -e
cd "$(dirname "$0")"
slices=$(mktemp -d)
trap 'rm -r "$slices"' EXIT
rm -rf Awake.app
mkdir -p Awake.app/Contents/MacOS Awake.app/Contents/Resources
swiftc -Osize -wmo -warnings-as-errors -Xfrontend -disable-reflection-metadata -Xlinker -no_data_const -Xlinker -dead_strip -Xlinker -no_function_starts -target arm64-apple-macos13.0 Sources/*.swift -o "$slices/arm64" &
arm64=$!
swiftc -Osize -wmo -warnings-as-errors -Xfrontend -disable-reflection-metadata -Xlinker -no_data_const -Xlinker -dead_strip -Xlinker -no_function_starts -target x86_64-apple-macos13.0 Sources/*.swift -o "$slices/x86_64" &
x86_64=$!
wait $arm64
wait $x86_64
lipo -create "$slices/arm64" "$slices/x86_64" -output Awake.app/Contents/MacOS/Awake
strip -x Awake.app/Contents/MacOS/Awake
plutil -convert binary1 -o Awake.app/Contents/Info.plist Info.plist
case "$1" in
  --self-updating)
    plutil -insert AwakeSelfUpdating -bool YES Awake.app/Contents/Info.plist
    ;;
  --installable)
    ;;
  *)
    plutil -replace CFBundleIdentifier -string local.awake.dev Awake.app/Contents/Info.plist
    defaults write local.awake.dev didSetUpOpenAtLogin -bool true
    ;;
esac
cp Resources/AppIcon.icns Awake.app/Contents/Resources/
codesign --force --sign - Awake.app
lipo Awake.app/Contents/MacOS/Awake -thin arm64 -output "$slices/arm64"
lipo Awake.app/Contents/MacOS/Awake -thin x86_64 -output "$slices/x86_64"
lipo -create "$slices/arm64" "$slices/x86_64" -output Awake.app/Contents/MacOS/Awake
codesign --verify --strict Awake.app
echo "Built $(pwd)/Awake.app"
