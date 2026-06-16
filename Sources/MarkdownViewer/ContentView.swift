import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ViewerModel

    /// Filename, marked with a bullet + "Updated" when reloaded from disk.
    private func titleText(for url: URL) -> String {
        model.lastExternalUpdate == nil
            ? url.lastPathComponent
            : "● \(url.lastPathComponent) — Updated"
    }

    /// Timestamp of the last external update, shown next to the title.
    private func subtitleText() -> String {
        guard let when = model.lastExternalUpdate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return "Updated \(f.string(from: when))"
    }

    var body: some View {
        Group {
            if let url = model.url {
                MarkdownWebView(url: url, reloadToken: model.reloadToken)
                    .id(url)
                    .navigationTitle(titleText(for: url))
                    .navigationSubtitle(subtitleText())
            } else {
                EmptyState()
            }
        }
    }
}

/// Shown when no file is open: a prompt to pick one, plus a recent-files list
/// for one-click reopening.
private struct EmptyState: View {
    @EnvironmentObject private var model: ViewerModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Markdown Viewer")
                .font(.title2.weight(.semibold))
            Text("Open a Markdown or text file to preview it.")
                .foregroundStyle(.secondary)
            Button("Open…") { model.openPanel() }
                .keyboardShortcut("o", modifiers: .command)

            if !model.recent.isEmpty {
                Divider().frame(maxWidth: 320)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(model.recent.prefix(8), id: \.self) { item in
                        Button {
                            model.open(item)
                        } label: {
                            Label(item.lastPathComponent, systemImage: "doc.text")
                                .lineLimit(1)
                        }
                        .buttonStyle(.link)
                        .help(item.path)
                    }
                }
                .frame(maxWidth: 320, alignment: .leading)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.pruneMissingRecent() }
    }
}
