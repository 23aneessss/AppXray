import Foundation

/// Maps Info.plist `NS*UsageDescription` keys to friendly resource names.
///
/// These keys are the resources an app declares it may prompt the user for at
/// runtime (the strings shown in the system permission dialog). The presence of
/// a key means the app *can* ask; it is not proof the app uses the resource.
enum PrivacyUsageCatalog {

    /// The friendly resource name for a usage-description key, or `nil` if the
    /// key is not a recognised privacy usage string.
    static func resource(forKey key: String) -> String? {
        entries[key]
    }

    /// All known usage-description keys.
    static var knownKeys: [String] { Array(entries.keys) }

    private static let entries: [String: String] = [
        "NSCameraUsageDescription": "Camera",
        "NSMicrophoneUsageDescription": "Microphone",
        "NSScreenCaptureUsageDescription": "Screen Recording",
        "NSLocationUsageDescription": "Location",
        "NSLocationWhenInUseUsageDescription": "Location (When In Use)",
        "NSLocationAlwaysUsageDescription": "Location (Always)",
        "NSLocationAlwaysAndWhenInUseUsageDescription": "Location (Always)",
        "NSContactsUsageDescription": "Contacts",
        "NSCalendarsUsageDescription": "Calendars",
        "NSCalendarsFullAccessUsageDescription": "Calendars (Full Access)",
        "NSRemindersUsageDescription": "Reminders",
        "NSRemindersFullAccessUsageDescription": "Reminders (Full Access)",
        "NSPhotoLibraryUsageDescription": "Photo Library",
        "NSPhotoLibraryAddUsageDescription": "Photo Library (Add)",
        "NSAppleEventsUsageDescription": "Automation (Apple Events)",
        "NSBluetoothAlwaysUsageDescription": "Bluetooth",
        "NSBluetoothPeripheralUsageDescription": "Bluetooth Peripheral",
        "NSLocalNetworkUsageDescription": "Local Network",
        "NSMotionUsageDescription": "Motion & Fitness",
        "NSSpeechRecognitionUsageDescription": "Speech Recognition",
        "NSDesktopFolderUsageDescription": "Desktop Folder",
        "NSDocumentsFolderUsageDescription": "Documents Folder",
        "NSDownloadsFolderUsageDescription": "Downloads Folder",
        "NSRemovableVolumesUsageDescription": "Removable Volumes",
        "NSNetworkVolumesUsageDescription": "Network Volumes",
        "NSFileProviderDomainUsageDescription": "File Provider Domain",
        "NSSystemAdministrationUsageDescription": "System Administration",
        "NSSystemExtensionUsageDescription": "System Extension",
        "NSHealthShareUsageDescription": "Health (Read)",
        "NSHealthUpdateUsageDescription": "Health (Write)",
        "NSFocusStatusUsageDescription": "Focus Status",
        "NSUserTrackingUsageDescription": "Tracking (across apps & sites)"
    ]
}
