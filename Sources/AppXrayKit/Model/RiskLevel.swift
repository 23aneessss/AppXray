import Foundation

/// The severity attached to a finding, badge, or entitlement.
///
/// App X-Ray deliberately avoids a single fabricated "safety score". Instead,
/// every signal carries an honest, explained ``RiskLevel`` and the reader draws
/// their own conclusions.
public enum RiskLevel: String, Sendable, Codable, CaseIterable, Comparable {
    /// Neutral, factual information. No cause for concern on its own.
    case info
    /// Worth a second look in context (e.g. a development build, a sensitive
    /// entitlement, an unnotarized identified developer).
    case notable
    /// A strong signal that warrants scrutiny (e.g. unsigned code, sandbox
    /// escapes, library-validation disabled).
    case high

    private var order: Int {
        switch self {
        case .info: return 0
        case .notable: return 1
        case .high: return 2
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.order < rhs.order
    }
}
