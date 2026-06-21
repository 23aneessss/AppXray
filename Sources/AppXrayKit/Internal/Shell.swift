import Foundation

/// A tiny wrapper for the documented shell fallbacks (`spctl`, etc.). The core
/// analysis prefers native `Security.framework` APIs; this is only used where no
/// stable Swift API is exposed.
enum Shell {
    struct Output {
        let status: Int32
        let stdout: String
        let stderr: String
    }

    /// Run an executable with arguments, capturing output. Returns `nil` if the
    /// process could not be launched.
    static func run(_ launchPath: String, _ arguments: [String]) -> Output? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let outPipe = Pipe(), errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        do {
            try process.run()
        } catch {
            Log.inspector.error("Failed to launch \(launchPath, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Output(status: process.terminationStatus,
                      stdout: String(decoding: outData, as: UTF8.self),
                      stderr: String(decoding: errData, as: UTF8.self))
    }
}
