import Foundation

/// A friendly description of a known entitlement key.
struct EntitlementInfo: Sendable {
    let title: String
    let explanation: String
    let risk: RiskLevel
}

/// Maps raw reverse-DNS entitlement keys to friendly titles, plain-language
/// explanations, and an honest ``RiskLevel``.
///
/// Unknown keys are still surfaced by the analyzer (as `info`); this catalog
/// only adds human context to the ones we recognise. Risk levels follow the
/// spirit of the brief: a sensitive entitlement means the app *can* request a
/// capability, not that it *does* use it.
enum EntitlementsCatalog {

    /// Looks up a known entitlement. Returns `nil` for keys we don't recognise.
    static func info(forKey key: String) -> EntitlementInfo? {
        entries[key]
    }

    /// Some entitlements are namespaced and risky as a family (e.g. sandbox
    /// temporary exceptions). This catches them by prefix.
    static func info(forPrefixMatch key: String) -> EntitlementInfo? {
        for (prefix, info) in prefixEntries where key.hasPrefix(prefix) {
            return info
        }
        return nil
    }

    /// Resolve a key against exact entries first, then prefix families.
    static func resolve(_ key: String) -> EntitlementInfo? {
        info(forKey: key) ?? info(forPrefixMatch: key)
    }

    // MARK: - Exact-match catalog

    private static let entries: [String: EntitlementInfo] = [
        // Sandbox
        "com.apple.security.app-sandbox": .init(
            title: "App Sandbox",
            explanation: "The app runs inside Apple's sandbox, which restricts what files, hardware, and services it can reach without explicit entitlements.",
            risk: .info),

        // Network
        "com.apple.security.network.client": .init(
            title: "Outgoing network connections",
            explanation: "The app can open outbound network connections (e.g. talk to servers on the internet).",
            risk: .info),
        "com.apple.security.network.server": .init(
            title: "Incoming network connections",
            explanation: "The app can listen for and accept incoming network connections.",
            risk: .notable),

        // Hardware / capture
        "com.apple.security.device.camera": .init(
            title: "Camera",
            explanation: "The app can request access to the camera.",
            risk: .notable),
        "com.apple.security.device.microphone": .init(
            title: "Microphone",
            explanation: "The app can request access to the microphone.",
            risk: .notable),
        "com.apple.security.device.audio-input": .init(
            title: "Audio input",
            explanation: "The app can request access to audio-input devices.",
            risk: .notable),
        "com.apple.security.device.bluetooth": .init(
            title: "Bluetooth",
            explanation: "The app can use Bluetooth.",
            risk: .notable),
        "com.apple.security.device.usb": .init(
            title: "USB devices",
            explanation: "The app can communicate with USB devices.",
            risk: .notable),
        "com.apple.security.print": .init(
            title: "Printing",
            explanation: "The app can print.",
            risk: .info),

        // Personal information
        "com.apple.security.personal-information.addressbook": .init(
            title: "Contacts",
            explanation: "The app can request access to your Contacts.",
            risk: .notable),
        "com.apple.security.personal-information.calendars": .init(
            title: "Calendars",
            explanation: "The app can request access to your Calendars.",
            risk: .notable),
        "com.apple.security.personal-information.location": .init(
            title: "Location",
            explanation: "The app can request access to your location.",
            risk: .notable),
        "com.apple.security.personal-information.photos-library": .init(
            title: "Photos Library",
            explanation: "The app can request access to your Photos library.",
            risk: .notable),

        // File access
        "com.apple.security.files.user-selected.read-only": .init(
            title: "User-selected files (read-only)",
            explanation: "The app can read files the user explicitly opens or drops in.",
            risk: .info),
        "com.apple.security.files.user-selected.read-write": .init(
            title: "User-selected files (read/write)",
            explanation: "The app can read and write files the user explicitly chooses.",
            risk: .info),
        "com.apple.security.files.downloads.read-only": .init(
            title: "Downloads folder (read-only)",
            explanation: "The app can read your Downloads folder.",
            risk: .notable),
        "com.apple.security.files.downloads.read-write": .init(
            title: "Downloads folder (read/write)",
            explanation: "The app can read and write your Downloads folder.",
            risk: .notable),
        "com.apple.security.files.desktop.read-only": .init(
            title: "Desktop folder (read-only)",
            explanation: "The app can read your Desktop folder.",
            risk: .notable),
        "com.apple.security.files.desktop.read-write": .init(
            title: "Desktop folder (read/write)",
            explanation: "The app can read and write your Desktop folder.",
            risk: .notable),
        "com.apple.security.files.documents.read-only": .init(
            title: "Documents folder (read-only)",
            explanation: "The app can read your Documents folder.",
            risk: .notable),
        "com.apple.security.files.documents.read-write": .init(
            title: "Documents folder (read/write)",
            explanation: "The app can read and write your Documents folder.",
            risk: .notable),
        "com.apple.security.files.all": .init(
            title: "All files",
            explanation: "The app requests broad access to the file system. This is a wide-reaching capability.",
            risk: .high),

        // Automation
        "com.apple.security.automation.apple-events": .init(
            title: "Control other apps (Apple Events)",
            explanation: "The app can send Apple Events to automate or control other applications.",
            risk: .notable),

        // Code-signing relaxations (the risky family)
        "com.apple.security.cs.disable-library-validation": .init(
            title: "Library validation disabled",
            explanation: "The app can load libraries and plug-ins that are not signed by the same team or Apple — weakening a key code-integrity protection.",
            risk: .high),
        "com.apple.security.cs.allow-unsigned-executable-memory": .init(
            title: "Unsigned executable memory allowed",
            explanation: "The app can create executable memory from unsigned code (common in browsers/runtimes, but a notable relaxation).",
            risk: .notable),
        "com.apple.security.cs.allow-jit": .init(
            title: "Just-in-time compilation allowed",
            explanation: "The app can generate and run code at runtime (e.g. a JavaScript engine).",
            risk: .notable),
        "com.apple.security.cs.allow-dyld-environment-variables": .init(
            title: "DYLD environment variables allowed",
            explanation: "The app can be influenced by DYLD_* environment variables, which can be used to inject libraries.",
            risk: .notable),
        "com.apple.security.cs.disable-executable-page-protection": .init(
            title: "Executable page protection disabled",
            explanation: "The app disables a memory protection that normally prevents code from being modified after signing.",
            risk: .high),
        "com.apple.security.cs.debugger": .init(
            title: "Debugger entitlement",
            explanation: "The app can attach to and debug other processes.",
            risk: .high),
        "com.apple.security.get-task-allow": .init(
            title: "Debuggable (get-task-allow)",
            explanation: "Other processes can inspect and control this app. Expected for development builds; unexpected in shipping software.",
            risk: .notable),

        // Keychain
        "keychain-access-groups": .init(
            title: "Keychain access groups",
            explanation: "The app declares shared keychain groups it can read/write credentials in.",
            risk: .info),

        // Associated Domains
        "com.apple.developer.associated-domains": .init(
            title: "Associated Domains",
            explanation: "The app is associated with specific web domains (universal links, web credentials).",
            risk: .info)
    ]

    // MARK: - Prefix families

    private static let prefixEntries: [(String, EntitlementInfo)] = [
        ("com.apple.security.temporary-exception", .init(
            title: "Sandbox temporary exception",
            explanation: "The app uses a sandbox temporary exception to reach something the sandbox would normally block — effectively a sanctioned sandbox escape.",
            risk: .high))
    ]
}
