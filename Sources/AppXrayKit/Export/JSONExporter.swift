import Foundation

public extension AppReport {
    /// The full report encoded as pretty-printed, stable-key-ordered JSON.
    ///
    /// - Throws: an encoding error if the report cannot be serialised.
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    /// Convenience: the JSON report as a `String`.
    func jsonString() throws -> String {
        String(decoding: try jsonData(), as: UTF8.self)
    }
}
