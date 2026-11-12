#!/bin/bash
# Build "Raman Xc Analyzer.app" with the Xcode Command Line Tools only (no Xcode).
#   bash build.sh          -> build/Raman Xc Analyzer.app
#   bash build.sh --zip    -> also dist/RamanXcAnalyzer-<version>-macOS.zip
set -euo pipefail
cd "$(dirname "$0")"
VER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" mac/Info.plist)
APP="build/Raman Xc Analyzer.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/tmp

# binary for this Mac, plus the other architecture when the toolchain can link it (Xcode can; the
# Command Line Tools alone often cannot). The release build on GitHub makes a universal binary.
HOST=$(uname -m); [ "$HOST" = "arm64" ] && OTHER=x86_64 || OTHER=arm64
swiftc -O -target "$HOST-apple-macos11.0" -o build/tmp/host mac/main.swift
if swiftc -O -target "$OTHER-apple-macos11.0" -o build/tmp/other mac/main.swift >/dev/null 2>&1; then
  lipo -create build/tmp/host build/tmp/other -output "$APP/Contents/MacOS/RamanXcAnalyzer"
  echo "Architectures: arm64 + x86_64"
else
  cp build/tmp/host "$APP/Contents/MacOS/RamanXcAnalyzer"
  echo "Architectures: $HOST only (the other one could not be linked with this toolchain)"
fi

cp mac/Info.plist "$APP/Contents/Info.plist"
cp index.html "$APP/Contents/Resources/"
cp -R vendor "$APP/Contents/Resources/"

# icon: mac/icon_1024.png -> AppIcon.icns
IS=build/tmp/AppIcon.iconset; mkdir -p "$IS"
for s in 16 32 128 256 512; do
  sips -z $s $s       mac/icon_1024.png --out "$IS/icon_${s}x${s}.png"    >/dev/null
  sips -z $((s*2)) $((s*2)) mac/icon_1024.png --out "$IS/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$IS" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf build/tmp

codesign --force --deep -s - "$APP"        # ad-hoc signature (no Developer ID)
echo "Built: $APP (v$VER)"

if [ "${1:-}" = "--zip" ]; then
  mkdir -p dist
  ditto -c -k --keepParent "$APP" "dist/RamanXcAnalyzer-$VER-macOS.zip"
  echo "Zip:   dist/RamanXcAnalyzer-$VER-macOS.zip"
fi
