#!/bin/bash
# Build Markdown Viewer, install it to /Applications, and sign with the stable
# Apple Development identity if one is available (otherwise leaves it ad-hoc).
set -euo pipefail

cd "$(dirname "$0")"

BUILT="./build/Build/Products/Debug/MarkdownViewer.app"
INSTALL="/Applications/Markdown Viewer.app"
IDENTITY="$(security find-identity -v -p codesigning | grep -o '"Apple Development:[^"]*"' | head -1 | tr -d '"')"

echo "==> Generating project"
xcodegen generate >/dev/null

echo "==> Building"
xcodebuild -project MarkdownViewer.xcodeproj -scheme MarkdownViewer \
    -configuration Debug -derivedDataPath ./build build \
    2>&1 | grep -E "error:|BUILD" || true

echo "==> Installing to: $INSTALL"
rm -rf "$INSTALL"
cp -R "$BUILT" "$INSTALL"

if [ -n "$IDENTITY" ]; then
    echo "==> Signing with: $IDENTITY"
    codesign --force --deep --sign "$IDENTITY" "$INSTALL"
    codesign -dvvv "$INSTALL" 2>&1 | grep -E "Authority=Apple Development|TeamIdentifier" | head -2
else
    echo "==> No Apple Development identity found; left ad-hoc signed."
fi

echo "==> Done: $INSTALL"
