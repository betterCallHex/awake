#!/bin/sh
set -e
cd "$(dirname "$0")/.."
build=$(mktemp -d)
trap 'rm -r "$build"' EXIT
swiftc -warnings-as-errors Sources/Updater.swift Tests/main.swift -o "$build/tests"
"$build/tests"
