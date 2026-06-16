import SwiftUI
import UniformTypeIdentifiers

/// Holds the currently displayed file, tracks recently viewed documents, and
/// watches the open file for on-disk changes so edits reload automatically.
@MainActor
final class ViewerModel: ObservableObject {
    @Published var url: URL?
    /// Bumped to force the WebView to re-read the file (e.g. after a save).
    @Published var reloadToken = 0
    /// Most-recently-viewed files, newest first.
    @Published private(set) var recent: [URL] = []
    /// Set when the current file was reloaded due to an on-disk change, so the
    /// UI can flag it as updated. Cleared when a file is (re)opened by the user.
    @Published private(set) var lastExternalUpdate: Date?

    private let recentKey = "RecentDocuments"
    private let maxRecent = 12

    private var watchTimer: Timer?
    private var lastModified: Date?

    init() { loadRecent() }

    // MARK: - Opening

    func open(_ url: URL) {
        self.url = url
        lastExternalUpdate = nil
        noteRecent(url)
        startWatching(url)
    }

    func reload() { reloadToken &+= 1 }

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

    // MARK: - Recent files

    private func loadRecent() {
        let paths = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
        recent = paths.map { URL(fileURLWithPath: $0) }
    }

    private func noteRecent(_ url: URL) {
        var paths = recent.map(\.path)
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > maxRecent { paths = Array(paths.prefix(maxRecent)) }
        UserDefaults.standard.set(paths, forKey: recentKey)
        recent = paths.map { URL(fileURLWithPath: $0) }
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    func clearRecent() {
        UserDefaults.standard.removeObject(forKey: recentKey)
        recent = []
    }

    /// Drop entries whose file no longer exists, so the menu stays useful.
    func pruneMissingRecent() {
        let existing = recent.filter { FileManager.default.fileExists(atPath: $0.path) }
        if existing.count != recent.count {
            recent = existing
            UserDefaults.standard.set(existing.map(\.path), forKey: recentKey)
        }
    }

    // MARK: - File watching

    /// Poll the open file's modification date and reload on change. Polling is
    /// resilient to atomic saves (write-to-temp + rename) that invalidate file
    /// descriptors, which editors commonly use.
    private func startWatching(_ url: URL) {
        watchTimer?.invalidate()
        lastModified = modificationDate(of: url)
        let timer = Timer(timeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkForChange() }
        }
        RunLoop.main.add(timer, forMode: .common)
        watchTimer = timer
    }

    private func checkForChange() {
        guard let url else { return }
        guard let date = modificationDate(of: url) else { return }
        if date != lastModified {
            lastModified = date
            lastExternalUpdate = Date()
            reload()
        }
    }

    private func modificationDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
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

                Menu("Open Recent") {
                    ForEach(model.recent, id: \.self) { item in
                        Button(item.lastPathComponent) { model.open(item) }
                    }
                    if !model.recent.isEmpty {
                        Divider()
                        Button("Clear Menu") { model.clearRecent() }
                    }
                }
                .disabled(model.recent.isEmpty)
            }
        }
    }
}
