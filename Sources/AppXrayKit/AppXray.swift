import Foundation

/// App X-Ray — a local, offline privacy & capability auditor for macOS apps.
///
/// Point ``AppXray/analyze(bundleAt:)`` at any `.app` bundle and it returns an
/// ``AppReport``: an honest, plain-language inventory of *what that app can
/// actually do* — read directly from the bundle and its code signature, not
/// from self-declared marketing claims.
///
/// All analysis is **static** and runs **100% offline**. Nothing is uploaded.
public enum AppXray {
    /// Fully offline static analysis of a `.app` bundle.
    ///
    /// - Parameter url: A file URL pointing at a macOS application bundle.
    /// - Returns: A complete ``AppReport`` describing the app's capabilities.
    /// - Throws: ``AppXrayError`` if the bundle cannot be read or parsed.
    public static func analyze(bundleAt url: URL) throws -> AppReport {
        try Analyzer().analyze(bundleAt: url)
    }
}
