#!/bin/sh
set -e
cd "$(dirname "$0")"
./build.sh
pkill -x Awake || true
rm -rf /Applications/Awake.app
cp -R Awake.app /Applications/
open /Applications/Awake.app
echo "Installed /Applications/Awake.app"
