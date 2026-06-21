import Foundation

/// Scans a binary for URL/hostname strings as a **heuristic** hint at the
/// endpoints an app might talk to.
///
/// This is explicitly *not* proof of any network connection — it is static
/// string extraction, and is always labelled as such in the output. Real
/// destinations require runtime observation (an optional Phase-2 module).
struct NetworkHintsScanner {

    let executableURL: URL?
    /// Cap the number of hints so reports stay readable.
    var limit: Int = 40

    func scan() -> [String] {
        guard let executableURL,
              let data = try? Data(contentsOf: executableURL, options: .mappedIfSafe) else {
            return []
        }

        // Extract printable ASCII runs, then match http(s) URLs within them.
        var hints = Set<String>()
        var current: [UInt8] = []
        current.reserveCapacity(256)

        func flush() {
            if current.count >= 8 {
                let s = String(decoding: current, as: UTF8.self)
                for host in Self.extractHosts(from: s) { hints.insert(host) }
            }
            current.removeAll(keepingCapacity: true)
        }

        for byte in data {
            if byte >= 0x20 && byte < 0x7f {
                current.append(byte)
                if current.count > 4096 { flush() }
            } else {
                flush()
            }
            if hints.count >= limit * 4 { break }
        }
        flush()

        return Array(hints).sorted().prefix(limit).map { $0 }
    }

    /// Pull `https://host` / `http://host` origins out of a string, returning
    /// the scheme+host (path stripped to keep hints compact).
    static func extractHosts(from string: String) -> [String] {
        guard string.contains("://") else { return [] }
        var results: [String] = []
        for scheme in ["https://", "http://"] {
            var search = string[...]
            while let range = search.range(of: scheme) {
                let rest = search[range.upperBound...]
                let host = rest.prefix { ch in
                    ch != "/" && ch != "\"" && ch != " " && ch != "'" && ch != ")"
                        && ch != "?" && ch != "%" && ch != "\\" && ch != ">"
                }
                if isPlausibleHost(host) {
                    results.append(scheme + host)
                }
                search = rest
            }
        }
        return results
    }

    static func isPlausibleHost(_ host: Substring) -> Bool {
        guard host.count >= 3, host.contains(".") else { return false }
        // Must look like a domain: letters/digits/.-, with a TLD-ish suffix.
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        guard host.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        guard let tld = host.split(separator: ".").last, tld.count >= 2,
              tld.allSatisfy({ $0.isLetter }) else { return false }
        return true
    }
}
