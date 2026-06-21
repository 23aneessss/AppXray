import SwiftUI
import AppXrayKit

extension RiskLevel {
    var color: Color {
        switch self {
        case .info: return .secondary
        case .notable: return .orange
        case .high: return .red
        }
    }

    var symbolName: String {
        switch self {
        case .info: return "info.circle"
        case .notable: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

extension SignatureInfo.Kind {
    var label: String {
        switch self {
        case .developerID: return "Developer ID"
        case .appleDevelopment: return "Apple Development"
        case .appleSystem: return "Apple System"
        case .adhoc: return "Ad-hoc (no identity)"
        case .unsigned: return "Unsigned"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .developerID, .appleSystem: return .green
        case .appleDevelopment, .adhoc, .other: return .orange
        case .unsigned: return .red
        }
    }
}
