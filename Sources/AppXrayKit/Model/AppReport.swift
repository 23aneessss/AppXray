import Foundation

/// The complete result of analysing a `.app` bundle.
///
/// An `AppReport` is a faithful, static, offline inventory of what an app *can*
/// do. Every field is read from the bundle on disk and its code signature —
/// never from the developer's marketing claims or App Store privacy label.
public struct AppReport: Sendable, Codable, Hashable {
    /// The absolute path to the analysed bundle.
    public let bundlePath: String
    /// The display name (`CFBundleDisplayName` / `CFBundleName` / file name).
    public let name: String
    /// The bundle identifier, e.g. `com.apple.calculator`.
    public let bundleID: String?
    /// The marketing version (`CFBundleShortVersionString`), with build if present.
    public let version: String?
    /// The minimum macOS the app declares it can run on.
    public let minimumOS: String?
    /// The CPU architectures the main executable supports, e.g. `["arm64", "x86_64"]`.
    public let architectures: [String]
    /// Whether the App Sandbox is enabled — a headline trust signal.
    public let isSandboxed: Bool
    /// Whether a valid notarization ticket is recognised by the system.
    public let isNotarized: Bool
    /// Whether Gatekeeper would accept the app, as reported by `SecAssessment`.
    public let gatekeeperAccepted: Bool
    /// The code-signature summary.
    public let signature: SignatureInfo
    /// Every entitlement the signature claims, annotated and risk-rated.
    public let entitlements: [EntitlementFinding]
    /// Privacy resources the app can prompt for, with the developer's stated reasons.
    public let privacyUsage: [PrivacyUsageFinding]
    /// Dynamic libraries the app links against.
    public let linkedLibraries: [LinkedLibrary]
    /// The subset of linked libraries that live under private framework paths.
    public let privateFrameworks: [String]
    /// Embedded bundles & executables (XPC services, login items, helpers…).
    public let nestedComponents: [NestedComponent]
    /// Custom URL schemes the app registers (its inbound integration surface).
    public let urlSchemes: [String]
    /// Associated Domains declared via entitlement.
    public let associatedDomains: [String]
    /// Heuristic endpoint hints scraped from strings. **Not proof of any connection.**
    public let networkHints: [String]
    /// The at-a-glance capability badges, derived from the findings above.
    public let badges: [CapabilityBadge]
    /// Plain-language warnings derived from the most important risk signals.
    public let warnings: [Finding]

    public init(
        bundlePath: String,
        name: String,
        bundleID: String?,
        version: String?,
        minimumOS: String?,
        architectures: [String],
        isSandboxed: Bool,
        isNotarized: Bool,
        gatekeeperAccepted: Bool,
        signature: SignatureInfo,
        entitlements: [EntitlementFinding],
        privacyUsage: [PrivacyUsageFinding],
        linkedLibraries: [LinkedLibrary],
        privateFrameworks: [String],
        nestedComponents: [NestedComponent],
        urlSchemes: [String],
        associatedDomains: [String],
        networkHints: [String],
        badges: [CapabilityBadge],
        warnings: [Finding]
    ) {
        self.bundlePath = bundlePath
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.minimumOS = minimumOS
        self.architectures = architectures
        self.isSandboxed = isSandboxed
        self.isNotarized = isNotarized
        self.gatekeeperAccepted = gatekeeperAccepted
        self.signature = signature
        self.entitlements = entitlements
        self.privacyUsage = privacyUsage
        self.linkedLibraries = linkedLibraries
        self.privateFrameworks = privateFrameworks
        self.nestedComponents = nestedComponents
        self.urlSchemes = urlSchemes
        self.associatedDomains = associatedDomains
        self.networkHints = networkHints
        self.badges = badges
        self.warnings = warnings
    }
}

/// Errors thrown by ``AppXray/analyze(bundleAt:)``.
public enum AppXrayError: Error, Sendable, Equatable {
    /// The path does not point at a readable `.app` bundle.
    case notABundle
    /// The bundle exists but its contents could not be read.
    case unreadable
    /// A code signature exists but could not be parsed.
    case signatureUnreadable
    /// The Mach-O executable could not be parsed.
    case machOParseFailed
}

extension AppXrayError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notABundle: return "The path does not point at a readable .app bundle."
        case .unreadable: return "The bundle could not be read (check Full Disk Access)."
        case .signatureUnreadable: return "The code signature could not be parsed."
        case .machOParseFailed: return "The Mach-O executable could not be parsed."
        }
    }
}
