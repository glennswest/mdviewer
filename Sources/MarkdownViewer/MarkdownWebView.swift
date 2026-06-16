import SwiftUI
import WebKit

/// Renders a Markdown (or plain-text) file in-app by converting it to XHTML and
/// displaying it in a WebView. Relative image paths resolve against the file's
/// own directory.
struct MarkdownWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let v = WKWebView()
        load(into: v)
        return v
    }

    func updateNSView(_ v: WKWebView, context: Context) { load(into: v) }

    private func load(into web: WKWebView) {
        let md = (try? String(contentsOf: url, encoding: .utf8)) ?? "_(could not read file)_"
        let bodyHTML: String
        if url.pathExtension.lowercased() == "txt" {
            bodyHTML = "<pre style=\"white-space:pre-wrap\">" + HTML.escape(md) + "</pre>"
        } else {
            bodyHTML = Markdown.toXHTML(md)
        }

        let html = """
        <!doctype html><html><head><meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <style>
        :root { color-scheme: light dark; }
        body { font-family: -apple-system, Georgia, serif; line-height: 1.55;
               max-width: 44em; margin: 0 auto; padding: 1.5em;
               color: #222; background: #ffffff; }
        h1 { font-size: 1.7em; } h2 { font-size: 1.35em; margin-top: 1.3em; }
        h3 { font-size: 1.1em; } h4, h5, h6 { font-size: 1em; }
        hr { border: 0; border-top: 1px solid #ddd; margin: 1.4em 0; }
        em { color: #666; }
        a { color: #2a6; }
        blockquote { margin: 1em 0; padding: .2em 1em; border-left: 3px solid #ccc; color: #555; }
        code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .9em;
               background: rgba(127,127,127,.15); padding: .1em .35em; border-radius: 4px; }
        pre { background: rgba(127,127,127,.12); padding: 1em; border-radius: 8px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        li { margin: .35em 0; }
        figure { margin: 1em 0; text-align: center; }
        figure img { max-width: 100%; height: auto; border-radius: 6px; }
        figcaption { font-size: .85em; color: #888; margin-top: .4em; }
        @media (prefers-color-scheme: dark) {
            body { color: #ddd; background: #1e1e1e; }
            a { color: #5cd; }
            hr { border-top-color: #444; }
            em { color: #aaa; }
            blockquote { border-left-color: #555; color: #bbb; }
            figcaption { color: #999; }
        }
        </style></head>
        <body>\(bodyHTML)</body></html>
        """
        // baseURL = the file's directory so relative image paths resolve.
        web.loadFileURL(writeTemp(html), allowingReadAccessTo: url.deletingLastPathComponent())
    }

    /// Write the rendered HTML next to the source so relative images resolve.
    private func writeTemp(_ html: String) -> URL {
        let out = url.deletingLastPathComponent().appendingPathComponent(".preview.html")
        try? html.data(using: .utf8)?.write(to: out)
        return out
    }
}
