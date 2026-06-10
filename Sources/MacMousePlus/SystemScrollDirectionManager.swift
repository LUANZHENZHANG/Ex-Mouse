import Foundation

final class SystemScrollDirectionManager {
    private var originalValue: Bool?

    func currentNaturalScrolling() -> Bool {
        let globalDefaults = UserDefaults(suiteName: UserDefaults.globalDomain)
        return globalDefaults?.object(forKey: "com.apple.swipescrolldirection") as? Bool ?? true
    }

    func captureOriginalIfNeeded() {
        if originalValue == nil {
            originalValue = currentNaturalScrolling()
        }
    }

    func forceNaturalScrolling() {
        captureOriginalIfNeeded()
        setGlobalNaturalScrolling(true)
    }

    func restoreOriginalIfNeeded() {
        guard let originalValue else {
            return
        }
        setGlobalNaturalScrolling(originalValue)
    }

    private func setGlobalNaturalScrolling(_ enabled: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "-g", "com.apple.swipescrolldirection", "-bool", enabled ? "true" : "false"]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Keep silent here; callers surface operational state via backend debug messages.
        }
    }
}
