import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ViewerModel

    var body: some View {
        Group {
            if let url = model.url {
                MarkdownWebView(url: url)
                    .id(url)
                    .navigationTitle(url.lastPathComponent)
            } else {
                EmptyState()
            }
        }
    }
}

/// Shown when no file is open: a prompt to pick one.
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
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
