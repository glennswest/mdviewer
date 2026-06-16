import SwiftUI
import UniformTypeIdentifiers

/// Holds the currently displayed file and handles opening new ones.
@MainActor
final class ViewerModel: ObservableObject {
    @Published var url: URL?

    func open(_ url: URL) { self.url = url }

    /// Show a standard Open panel filtered to Markdown / text files.
    func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .init(filenameExtension: "md") ?? .plainText,
            .init(filenameExtension: "markdown") ?? .plainText,
            .plainText,
            .text
        ]
        if panel.runModal() == .OK, let picked = panel.url {
            open(picked)
        }
    }
}

@main
struct MarkdownViewerApp: App {
    @StateObject private var model = ViewerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onOpenURL { model.open($0) }
                .frame(minWidth: 640, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { model.openPanel() }
                    .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
