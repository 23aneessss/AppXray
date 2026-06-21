import Foundation
import AppXrayKit

/// The command-line front end for AppXrayKit. Parses arguments by hand (no
/// third-party dependency) and renders reports as coloured terminal text,
/// Markdown, or JSON.
enum CLI {
    static let version = "0.1.0"

    static func run(arguments: [String]) -> Int32 {
        var paths: [String] = []
        var emitJSON = false
        var emitMarkdown = false
        var outPath: String?
        var noColor = ProcessInfo.processInfo.environment["NO_COLOR"] != nil
        var installed = false

        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            switch arg {
            case "--help", "-h": printUsage(); return 0
            case "--version", "-v": print("appxray \(version)"); return 0
            case "--json": emitJSON = true
            case "--markdown", "--md": emitMarkdown = true
            case "--no-color": noColor = true
            case "--installed": installed = true
            case "--out", "-o":
                i += 1
                guard i < arguments.count else { fputs("error: --out requires a file path\n", stderr); return 2 }
                outPath = arguments[i]
            default:
                if arg.hasPrefix("-") { fputs("error: unknown option \(arg)\n", stderr); return 2 }
                paths.append(arg)
            }
            i += 1
        }

        let palette = Palette(enabled: !noColor && isTTY())

        if installed {
            return runInstalled(palette: palette)
        }

        guard let path = paths.first else {
            printUsage()
            return 2
        }

        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        let report: AppReport
        do {
            report = try AppXray.analyze(bundleAt: url)
        } catch let error as AppXrayError {
            fputs("error: \(error)\n", stderr)
            return 1
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            return 1
        }

        let output: String
        if emitJSON {
            output = (try? report.jsonString()) ?? "{}"
        } else if emitMarkdown {
            output = report.markdown()
        } else {
            output = TerminalRenderer(palette: palette).render(report)
        }

        if let outPath {
            do {
                try output.write(toFile: outPath, atomically: true, encoding: .utf8)
                print("Wrote report to \(outPath)")
            } catch {
                fputs("error: could not write \(outPath): \(error.localizedDescription)\n", stderr)
                return 1
            }
        } else {
            print(output)
        }

        // Non-zero exit if a high-risk flag is present (useful for CI gating).
        return report.highestRisk == .high ? 3 : 0
    }

    // MARK: - --installed

    static func runInstalled(palette: Palette) -> Int32 {
        let appsDir = URL(fileURLWithPath: "/Applications")
        let apps = (try? FileManager.default.contentsOfDirectory(at: appsDir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "app" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        guard !apps.isEmpty else {
            print("No apps found in /Applications.")
            return 0
        }

        print(palette.bold("Scanning \(apps.count) apps in /Applications…\n"))
        func row(_ a: String, _ b: String, _ c: String, _ d: String, _ e: String) -> String {
            pad(a, 32) + pad(b, 12) + pad(c, 10) + pad(d, 9) + e
        }
        print(palette.bold(row("APP", "SIGNING", "SANDBOX", "NOTARY", "FLAGS")))
        print(String(repeating: "─", count: 78))

        var highRiskCount = 0
        for app in apps {
            guard let report = try? AppXray.analyze(bundleAt: app) else { continue }
            if report.highestRisk == .high { highRiskCount += 1 }
            let notary = report.isNotarized ? "yes" : (report.signature.kind == .appleSystem ? "—" : "no")
            let line = row(String(report.name.prefix(31)),
                           signingShort(report.signature.kind),
                           report.isSandboxed ? "yes" : "no",
                           notary,
                           flagsSummary(report))
            print(report.highestRisk == .high ? palette.red(line) : line)
        }

        print("\n\(apps.count) apps scanned, \(palette.bold("\(highRiskCount)")) with a high-risk flag.")
        return highRiskCount > 0 ? 3 : 0
    }

    static func signingShort(_ kind: SignatureInfo.Kind) -> String {
        switch kind {
        case .developerID: return "DeveloperID"
        case .appleDevelopment: return "AppleDev"
        case .appleSystem: return "Apple"
        case .adhoc: return "ad-hoc"
        case .unsigned: return "UNSIGNED"
        case .other: return "other"
        }
    }

    static func flagsSummary(_ report: AppReport) -> String {
        var flags: [String] = []
        if report.signature.kind == .unsigned { flags.append("unsigned") }
        if !report.privateFrameworks.isEmpty { flags.append("private-fw") }
        if report.badges.contains(where: { $0.label == "Installs background items" && $0.isOn }) {
            flags.append("bg-items")
        }
        let highs = report.warnings.filter { $0.risk == .high }.count
        if highs > 0 { flags.append("\(highs) high") }
        return flags.joined(separator: ", ")
    }

    // MARK: - Help

    static func isTTY() -> Bool { isatty(fileno(stdout)) == 1 }

    /// Left-justify `s` in a field of `width` columns (truncating if needed).
    static func pad(_ s: String, _ width: Int) -> String {
        if s.count >= width { return String(s.prefix(width - 1)) + " " }
        return s + String(repeating: " ", count: width - s.count)
    }

    static func printUsage() {
        print("""
        App X-Ray \(version) — an independent, offline privacy & capability auditor for macOS apps.

        USAGE:
          appxray <path-to-.app> [options]
          appxray --installed
          appxray --help | --version

        OPTIONS:
          --json            Emit the report as JSON.
          --markdown, --md  Emit the report as Markdown.
          --out, -o <file>  Write output to a file instead of stdout.
          --no-color        Disable ANSI colour (also honours NO_COLOR).
          --installed       Summarise every app in /Applications as a table.

        EXIT CODES:
          0  success         2  usage error
          1  analysis error  3  a high-risk flag was found (useful in CI)

        App X-Ray runs 100% offline and reports what an app *can* do, read from
        its bundle and code signature — not from self-declared privacy labels.
        """)
    }
}
