# Changelog

## [Unreleased]

### 2026-06-16
- **feat:** `setup.sh` installs an `mdviewer` CLI launcher to the PATH and
  registers the app as the default handler for `.md` / `.markdown` (via duti).
- **feat:** Watch the open file for on-disk changes and auto-reload edits.
- **feat:** Track recently viewed files — "Open Recent" menu and a recent list
  in the empty state for one-click reopening.
- **feat:** Flag the title bar (`● name — Updated`) with a timestamp subtitle
  when the document reloads from an external change.
- **fix:** Give the rendered page an explicit light/dark background so text
  contrast no longer depends on the window chrome.

### 2026-06-16 — initial
- **feat:** Initial standalone macOS Markdown Viewer app.
- **feat:** Markdown → XHTML converter supporting headings, ordered/unordered
  lists, blockquotes, fenced code blocks, inline code, bold/italic, horizontal
  rules, links, and images.
- **feat:** WebView renderer with light/dark mode and relative-image resolution.
- **feat:** Open files from Finder or via File ▸ Open… (⌘O); plain `.txt`
  renders as preformatted text.
- **build:** XcodeGen project, `build.sh` to build/install/sign to
  `/Applications`.
- **docs:** README and changelog.
