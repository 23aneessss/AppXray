import Foundation
import AppXrayKit

/// ANSI colour helpers. When `enabled` is false (piped output, `--no-color`,
/// or `NO_COLOR`), every method returns the string unchanged.
struct Palette {
    let enabled: Bool

    private func wrap(_ s: String, _ code: String) -> String {
        enabled ? "\u{001B}[\(code)m\(s)\u{001B}[0m" : s
    }

    func bold(_ s: String) -> String { wrap(s, "1") }
    func dim(_ s: String) -> String { wrap(s, "2") }
    func red(_ s: String) -> String { wrap(s, "31") }
    func green(_ s: String) -> String { wrap(s, "32") }
    func yellow(_ s: String) -> String { wrap(s, "33") }
    func blue(_ s: String) -> String { wrap(s, "34") }
    func cyan(_ s: String) -> String { wrap(s, "36") }

    /// Colour a string according to a risk level.
    func risk(_ s: String, _ level: RiskLevel) -> String {
        switch level {
        case .info: return s
        case .notable: return yellow(s)
        case .high: return red(s)
        }
    }

    func riskIcon(_ level: RiskLevel) -> String {
        switch level {
        case .info: return blue("•")
        case .notable: return yellow("▲")
        case .high: return red("●")
        }
    }
}
