@preconcurrency import ApplicationServices
import Foundation

enum PermissionManager {
    private static let bundleIdentifier = "com.zhangzeliang.macmouseplus"

    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    static func promptForAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt" as NSString: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func resetAccessibilityPermission() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleIdentifier]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
