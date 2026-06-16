#!/bin/bash
# Optional system integration:
#   1. Install the `mdviewer` CLI launcher onto your PATH.
#   2. Register Markdown Viewer as the default app for Markdown files.
#
# Run after ./build.sh has installed the app to /Applications.
set -euo pipefail

cd "$(dirname "$0")"

BINDIR="${BINDIR:-/usr/local/bin}"
BUNDLE_ID="com.glennwest.MarkdownViewer"

echo "==> Installing CLI launcher to: $BINDIR/mdviewer"
mkdir -p "$BINDIR"
install -m 0755 bin/mdviewer "$BINDIR/mdviewer"

if command -v duti >/dev/null 2>&1; then
    echo "==> Registering as default for Markdown files (via duti)"
    # By UTI (covers Finder content-type matching) and by extension.
    duti -s "$BUNDLE_ID" net.daringfireball.markdown all || true
    duti -s "$BUNDLE_ID" .md       all || true
    duti -s "$BUNDLE_ID" .markdown all || true
    echo "    .md now opens with: $(duti -x md 2>/dev/null | head -1)"
else
    echo "==> duti not found; skipping default-handler registration."
    echo "    Install it with: brew install duti"
fi

echo "==> Done. Try:  mdviewer README.md"
