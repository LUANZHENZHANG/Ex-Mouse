@preconcurrency import ApplicationServices
import Foundation

enum PermissionManager {
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    static func promptForAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt" as NSString: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
