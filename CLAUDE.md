# CLAUDE.md — Markdown Viewer

A standalone native macOS app that previews Markdown and plain-text files.

## Version
- Current: `0.1.0` (pre-1.0)
- Version locations (keep in sync):
  - `project.yml` → `MARKETING_VERSION`
  - `CHANGELOG.md` heading

## Architecture
- SwiftUI + WebKit, no third-party dependencies.
- `Markdown.swift` — dependency-free Markdown → XHTML converter.
- `MarkdownWebView.swift` — `NSViewRepresentable` WebView renderer + CSS.
- `MarkdownViewerApp.swift` — app entry, Open panel, `onOpenURL` file handling.
- `ContentView.swift` — root view + empty state.
- Built with XcodeGen (`project.yml`); `build.sh` builds, installs to
  `/Applications`, and signs.

## Build
```bash
./build.sh
```

## Work Plan
- [x] Extract the Markdown viewer into a standalone app
- [x] Build and install to /Applications
- [x] Public GitHub repo, original-project references removed
