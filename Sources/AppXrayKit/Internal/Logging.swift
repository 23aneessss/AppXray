import Foundation
import os

/// Shared logger for AppXrayKit. Library code never uses `print`.
enum Log {
    static let inspector = Logger(subsystem: "dev.appxray.kit", category: "inspector")
    static let signature = Logger(subsystem: "dev.appxray.kit", category: "signature")
    static let macho = Logger(subsystem: "dev.appxray.kit", category: "macho")
}
