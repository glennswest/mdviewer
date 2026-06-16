import Foundation

/// HTML-escaping helpers shared by the renderer.
enum HTML {
    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

/// Small, dependency-free Markdown → XHTML converter.
///
/// Supports: ATX headings (`#`..`######`), unordered lists (`-`/`*`),
/// ordered lists (`1.`), fenced code blocks (```), horizontal rules,
/// blockquotes, images, links, and inline bold/italic/code.
enum Markdown {
    static func toXHTML(_ md: String) -> String {
        var html = ""
        var inList = false
        var inOrdered = false
        var inCode = false
        var codeBuffer = ""

        func closeList() {
            if inList { html += "</ul>\n"; inList = false }
            if inOrdered { html += "</ol>\n"; inOrdered = false }
        }

        for raw in md.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            let t = line.trimmingCharacters(in: .whitespaces)

            // Fenced code blocks.
            if t.hasPrefix("```") {
                if inCode {
                    html += "<pre><code>\(HTML.escape(codeBuffer))</code></pre>\n"
                    codeBuffer = ""
                    inCode = false
                } else {
                    closeList()
                    inCode = true
                }
                continue
            }
            if inCode { codeBuffer += line + "\n"; continue }

            if t.isEmpty { closeList(); continue }
            if t == "---" || t == "***" || t == "___" { closeList(); html += "<hr/>\n"; continue }

            if t.hasPrefix("###### ") { closeList(); html += "<h6>\(inline(String(t.dropFirst(7))))</h6>\n"; continue }
            if t.hasPrefix("##### ") { closeList(); html += "<h5>\(inline(String(t.dropFirst(6))))</h5>\n"; continue }
            if t.hasPrefix("#### ") { closeList(); html += "<h4>\(inline(String(t.dropFirst(5))))</h4>\n"; continue }
            if t.hasPrefix("### ") { closeList(); html += "<h3>\(inline(String(t.dropFirst(4))))</h3>\n"; continue }
            if t.hasPrefix("## ") { closeList(); html += "<h2>\(inline(String(t.dropFirst(3))))</h2>\n"; continue }
            if t.hasPrefix("# ") { closeList(); html += "<h1>\(inline(String(t.dropFirst(2))))</h1>\n"; continue }

            if t.hasPrefix("> ") { closeList(); html += "<blockquote>\(inline(String(t.dropFirst(2))))</blockquote>\n"; continue }

            // Standalone image: ![alt](src)
            if t.hasPrefix("![") {
                closeList()
                if let r = t.range(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, options: .regularExpression) {
                    let m = String(t[r])
                    let alt = capture(m, 1), src = capture(m, 2)
                    html += "<figure><img src=\"\(HTML.escape(src))\" alt=\"\(HTML.escape(alt))\"/>"
                    if !alt.isEmpty { html += "<figcaption>\(HTML.escape(alt))</figcaption>" }
                    html += "</figure>\n"
                }
                continue
            }

            // Unordered list.
            if t.hasPrefix("- ") || t.hasPrefix("* ") {
                if inOrdered { html += "</ol>\n"; inOrdered = false }
                if !inList { html += "<ul>\n"; inList = true }
                html += "<li>\(inline(String(t.dropFirst(2))))</li>\n"
                continue
            }

            // Ordered list: "1. ", "2. ", ...
            if let r = t.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if inList { html += "</ul>\n"; inList = false }
                if !inOrdered { html += "<ol>\n"; inOrdered = true }
                html += "<li>\(inline(String(t[r.upperBound...])))</li>\n"
                continue
            }

            closeList()
            html += "<p>\(inline(t))</p>\n"
        }
        if inCode { html += "<pre><code>\(HTML.escape(codeBuffer))</code></pre>\n" }
        closeList()
        return html
    }

    // MARK: - Inline formatting

    private static func inline(_ s: String) -> String {
        var r = HTML.escape(s)
        r = links(r)
        r = wrap(r, "**", "<strong>", "</strong>")
        r = wrap(r, "`", "<code>", "</code>")
        r = wrap(r, "_", "<em>", "</em>")
        return r
    }

    /// Inline links: [text](url)
    private static func links(_ s: String) -> String {
        guard let re = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#) else { return s }
        let ns = s as NSString
        return re.stringByReplacingMatches(
            in: s, range: NSRange(location: 0, length: ns.length),
            withTemplate: "<a href=\"$2\">$1</a>")
    }

    /// Nth capture group of the first image-syntax match in `s`.
    static func capture(_ s: String, _ group: Int) -> String {
        guard let re = try? NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#),
              let m = re.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)),
              m.range(at: group).location != NSNotFound else { return "" }
        return (s as NSString).substring(with: m.range(at: group))
    }

    private static func wrap(_ s: String, _ marker: String, _ open: String, _ close: String) -> String {
        let parts = s.components(separatedBy: marker)
        guard parts.count >= 3 else { return s }
        var out = parts[0], openTag = true
        for p in parts.dropFirst() { out += (openTag ? open : close) + p; openTag.toggle() }
        return out
    }
}
