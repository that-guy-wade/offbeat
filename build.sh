#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app=${1:-"Dictation Pause.app"}
build_tmp=$(mktemp -d)
trap 'rm -rf "$build_tmp"' EXIT
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
for arch in arm64 x86_64; do
    xcrun swiftc -O -target "$arch-apple-macos15.0" main.swift MicrophoneGate.swift \
        -o "$build_tmp/$arch" || exit 1
done
xcrun lipo -create "$build_tmp/arm64" "$build_tmp/x86_64" \
    -output "$app/Contents/MacOS/DictationPause" || exit 1
cp Info.plist "$app/Contents/Info.plist"
cp LICENSE "$app/Contents/Resources/LICENSE"
codesign --force --sign - "$app" || exit 1
codesign --verify --strict "$app" || exit 1
echo "Built $app"
