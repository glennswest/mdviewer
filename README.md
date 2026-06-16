# Markdown Viewer

A tiny, native macOS app that previews Markdown and plain-text files in a clean,
readable layout. No dependencies, no Electron — just SwiftUI and WebKit.

## Features

- Renders Markdown to styled HTML in a WebView
- Light **and** dark mode (follows the system appearance)
- Supports headings, ordered/unordered lists, blockquotes, fenced code blocks,
  inline code, bold/italic, horizontal rules, links, and images
- Relative image paths resolve against the file's own directory
- Plain `.txt` files render as preformatted text
- Opens files from Finder (double-click / "Open With") or via **File ▸ Open…**
  (⌘O)

## Requirements

- macOS 13 or later
- [XcodeGen](https://github.com/yonwoo9/XcodeGen) (`brew install xcodegen`)
- Xcode command-line tools

## Build & Install

```bash
./build.sh
```

This generates the Xcode project, builds a Debug binary, installs it to
`/Applications/Markdown Viewer.app`, and code-signs it with your Apple
Development identity if one is available (otherwise it stays ad-hoc signed).

To open the project in Xcode instead:

```bash
xcodegen generate
open MarkdownViewer.xcodeproj
```

## System Integration (optional)

After installing the app, run:

```bash
./setup.sh
```

This:

- installs an `mdviewer` CLI launcher to `/usr/local/bin` so you can run
  `mdviewer file.md` from any terminal, and
- registers Markdown Viewer as the **default** app for `.md` / `.markdown`
  files (uses [`duti`](https://github.com/moretension/duti) —
  `brew install duti`).

Override the install location with `BINDIR=~/.local/bin ./setup.sh`.

## Project Layout

```
Sources/MarkdownViewer/
  MarkdownViewerApp.swift   App entry point, Open panel, file handling
  ContentView.swift         Root view + empty state
  MarkdownWebView.swift     WebView renderer + stylesheet
  Markdown.swift            Markdown → XHTML converter
  Info.plist                Document type associations
project.yml                 XcodeGen project definition
build.sh                    Build, install, sign
```

## License

MIT — see [license](license).
