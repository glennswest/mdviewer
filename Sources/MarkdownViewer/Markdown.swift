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
/// blockquotes, GFM pipe tables, images, links, and inline bold/italic/code.
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

        let lines = md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var i = 0
        while i < lines.count {
            let line = lines[i]
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
                i += 1; continue
            }
            if inCode { codeBuffer += line + "\n"; i += 1; continue }

            if t.isEmpty { closeList(); i += 1; continue }

            // GFM pipe table: a row containing `|` followed by a delimiter row.
            if t.contains("|"), i + 1 < lines.count, isTableDelimiter(lines[i + 1]) {
                closeList()
                let aligns = parseAlignments(lines[i + 1])
                html += "<table>\n<thead>\n<tr>"
                for (idx, cell) in splitRow(t).enumerated() {
                    html += "<th\(alignAttr(aligns, idx))>\(inline(cell))</th>"
                }
                html += "</tr>\n</thead>\n<tbody>\n"
                i += 2
                while i < lines.count {
                    let row = lines[i].trimmingCharacters(in: .whitespaces)
                    if row.isEmpty || !row.contains("|") { break }
                    html += "<tr>"
                    for (idx, cell) in splitRow(row).enumerated() {
                        html += "<td\(alignAttr(aligns, idx))>\(inline(cell))</td>"
                    }
                    html += "</tr>\n"
                    i += 1
                }
                html += "</tbody>\n</table>\n"
                continue
            }

            if t == "---" || t == "***" || t == "___" { closeList(); html += "<hr/>\n"; i += 1; continue }

            if t.hasPrefix("###### ") { closeList(); html += "<h6>\(inline(String(t.dropFirst(7))))</h6>\n"; i += 1; continue }
            if t.hasPrefix("##### ") { closeList(); html += "<h5>\(inline(String(t.dropFirst(6))))</h5>\n"; i += 1; continue }
            if t.hasPrefix("#### ") { closeList(); html += "<h4>\(inline(String(t.dropFirst(5))))</h4>\n"; i += 1; continue }
            if t.hasPrefix("### ") { closeList(); html += "<h3>\(inline(String(t.dropFirst(4))))</h3>\n"; i += 1; continue }
            if t.hasPrefix("## ") { closeList(); html += "<h2>\(inline(String(t.dropFirst(3))))</h2>\n"; i += 1; continue }
            if t.hasPrefix("# ") { closeList(); html += "<h1>\(inline(String(t.dropFirst(2))))</h1>\n"; i += 1; continue }

            if t.hasPrefix("> ") { closeList(); html += "<blockquote>\(inline(String(t.dropFirst(2))))</blockquote>\n"; i += 1; continue }

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
                i += 1; continue
            }

            // Unordered list.
            if t.hasPrefix("- ") || t.hasPrefix("* ") {
                if inOrdered { html += "</ol>\n"; inOrdered = false }
                if !inList { html += "<ul>\n"; inList = true }
                html += "<li>\(inline(String(t.dropFirst(2))))</li>\n"
                i += 1; continue
            }

            // Ordered list: "1. ", "2. ", ...
            if let r = t.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if inList { html += "</ul>\n"; inList = false }
                if !inOrdered { html += "<ol>\n"; inOrdered = true }
                html += "<li>\(inline(String(t[r.upperBound...])))</li>\n"
                i += 1; continue
            }

            closeList()
            html += "<p>\(inline(t))</p>\n"
            i += 1
        }
        if inCode { html += "<pre><code>\(HTML.escape(codeBuffer))</code></pre>\n" }
        closeList()
        return html
    }

    // MARK: - GFM tables

    /// A delimiter row separates a table header from its body, e.g.
    /// `| --- | :--: | --: |`. Each cell is dashes with optional alignment
    /// colons. Requires at least one pipe so a bare `---` rule isn't mistaken
    /// for a table.
    private static func isTableDelimiter(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.contains("|") else { return false }
        let cells = splitRow(t)
        guard !cells.isEmpty else { return false }
        for cell in cells where cell.range(of: #"^:?-+:?$"#, options: .regularExpression) == nil {
            return false
        }
        return true
    }

    /// Split a table row into trimmed cells, dropping the optional leading and
    /// trailing pipes and honouring escaped `\|` separators.
    private static func splitRow(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s.removeFirst() }
        if s.hasSuffix("|") { s.removeLast() }
        return s.replacingOccurrences(of: "\\|", with: "\u{0001}")
            .components(separatedBy: "|")
            .map { $0.replacingOccurrences(of: "\u{0001}", with: "|").trimmingCharacters(in: .whitespaces) }
    }

    /// Per-column alignment ("left" / "right" / "center" / "") from a delimiter row.
    private static func parseAlignments(_ line: String) -> [String] {
        splitRow(line).map { cell in
            let left = cell.hasPrefix(":"), right = cell.hasSuffix(":")
            if left && right { return "center" }
            if right { return "right" }
            if left { return "left" }
            return ""
        }
    }

    /// Inline `style="text-align:…"` for column `idx`, or "" when unaligned.
    private static func alignAttr(_ aligns: [String], _ idx: Int) -> String {
        guard idx < aligns.count, !aligns[idx].isEmpty else { return "" }
        return " style=\"text-align:\(aligns[idx])\""
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
