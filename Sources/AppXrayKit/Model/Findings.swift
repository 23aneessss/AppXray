import Foundation

/// A general, plain-language finding (used for warnings and derived notes).
public struct Finding: Sendable, Codable, Hashable {
    /// A short, human-readable headline.
    public let title: String
    /// A fuller explanation of what was observed and why it matters.
    public let detail: String
    /// The honest severity of this finding.
    public let risk: RiskLevel

    public init(title: String, detail: String, risk: RiskLevel) {
        self.title = title
        self.detail = detail
        self.risk = risk
    }
}

/// A single entitlement claimed by the app's code signature, annotated with a
/// friendly title and explanation drawn from App X-Ray's entitlements catalog.
public struct EntitlementFinding: Sendable, Codable, Hashable {
    /// The raw reverse-DNS entitlement key, e.g. `com.apple.security.app-sandbox`.
    public let key: String
    /// The rendered value (bool / string / array), e.g. `"true"` or `"3 items"`.
    public let valueDescription: String
    /// A friendly title from the catalog, or the raw key if unknown.
    public let title: String
    /// What this entitlement lets the app do, in plain language.
    public let explanation: String
    /// The honest severity of the app holding this entitlement.
    public let risk: RiskLevel

    public init(key: String, valueDescription: String, title: String, explanation: String, risk: RiskLevel) {
        self.key = key
        self.valueDescription = valueDescription
        self.title = title
        self.explanation = explanation
        self.risk = risk
    }
}

/// A privacy resource the app can prompt for, taken from an Info.plist
/// `NS*UsageDescription` string, paired with the developer's stated reason.
public struct PrivacyUsageFinding: Sendable, Codable, Hashable {
    /// The friendly resource name, e.g. `"Camera"`, `"Microphone"`.
    public let resource: String
    /// The Info.plist key, e.g. `NSCameraUsageDescription`.
    public let usageKey: String
    /// The developer's stated reason, verbatim from the bundle.
    public let statedReason: String

    public init(resource: String, usageKey: String, statedReason: String) {
        self.resource = resource
        self.usageKey = usageKey
        self.statedReason = statedReason
    }
}

/// A dynamic library the main executable (or a nested binary) links against.
public struct LinkedLibrary: Sendable, Codable, Hashable {
    /// The load path recorded in the Mach-O load command.
    public let path: String
    /// Whether the path lives under a system framework location.
    public let isSystem: Bool
    /// Whether the path lives under `/System/Library/PrivateFrameworks` — a
    /// signal of undocumented-API usage.
    public let isPrivateFramework: Bool
    /// Whether this is a weak link (`LC_LOAD_WEAK_DYLIB`).
    public let isWeak: Bool

    public init(path: String, isSystem: Bool, isPrivateFramework: Bool, isWeak: Bool) {
        self.path = path
        self.isSystem = isSystem
        self.isPrivateFramework = isPrivateFramework
        self.isWeak = isWeak
    }
}

/// An embedded bundle or executable found inside the app: an XPC service, login
/// item, helper, framework, or bundled updater.
public struct NestedComponent: Sendable, Codable, Hashable {
    /// The kind of component, e.g. `"XPC Service"`, `"Login Item"`, `"Helper"`,
    /// `"Framework"`, `"Updater"`.
    public let kind: String
    /// The path relative to the app bundle.
    public let path: String
    /// A one-line summary of the component's own code signature.
    public let signingSummary: String
    /// Whether the component declares the App Sandbox (nil if unknown).
    public let sandboxed: Bool?

    public init(kind: String, path: String, signingSummary: String, sandboxed: Bool?) {
        self.kind = kind
        self.path = path
        self.signingSummary = signingSummary
        self.sandboxed = sandboxed
    }
}

/// The code-signature summary for an app bundle.
public struct SignatureInfo: Sendable, Codable, Hashable {
    /// The kind of signing identity behind the bundle.
    public enum Kind: String, Sendable, Codable {
        /// Signed with a Developer ID certificate — meant for distribution outside the App Store.
        case developerID
        /// Signed with a development certificate — not meant for distribution.
        case appleDevelopment
        /// Built-in Apple software (e.g. `Software Signing`), trusted.
        case appleSystem
        /// Ad-hoc signed (no identity).
        case adhoc
        /// No code signature at all.
        case unsigned
        /// A signing kind App X-Ray did not recognise.
        case other
    }

    /// The derived signing kind.
    public let kind: Kind
    /// The Apple Team Identifier, or nil (e.g. for Apple system apps).
    public let teamID: String?
    /// The signing identifier (typically the bundle id).
    public let signingIdentifier: String?
    /// The certificate authority chain, leaf first.
    public let authorities: [String]
    /// Whether the Hardened Runtime (`CS_RUNTIME`) is enabled.
    public let hardenedRuntime: Bool
    /// Whether the app is debuggable (`get-task-allow`).
    public let isDebuggable: Bool

    public init(kind: Kind, teamID: String?, signingIdentifier: String?, authorities: [String], hardenedRuntime: Bool, isDebuggable: Bool) {
        self.kind = kind
        self.teamID = teamID
        self.signingIdentifier = signingIdentifier
        self.authorities = authorities
        self.hardenedRuntime = hardenedRuntime
        self.isDebuggable = isDebuggable
    }
}

/// An at-a-glance capability summary, derived from the detailed findings.
public struct CapabilityBadge: Sendable, Codable, Hashable {
    /// The badge label, e.g. `"Sandboxed"`, `"Notarized"`, `"Can record screen"`.
    public let label: String
    /// Whether the capability is present / on.
    public let isOn: Bool
    /// The honest severity associated with this capability being on.
    public let risk: RiskLevel

    public init(label: String, isOn: Bool, risk: RiskLevel) {
        self.label = label
        self.isOn = isOn
        self.risk = risk
    }
}
