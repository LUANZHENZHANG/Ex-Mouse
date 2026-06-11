import Darwin
import Foundation

final class SystemScrollDirectionManager {
    private enum Keys {
        static let overrideActive = "scrollDirectionOverrideActive"
        static let originalValue = "scrollDirectionOriginalValue"
        static let ownerPID = "scrollDirectionOwnerPID"
    }

    private let defaults: UserDefaults
    private var originalValue: Bool?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restoreInterruptedOverrideIfNeeded()
    }

    func currentNaturalScrolling() -> Bool {
        let globalDefaults = UserDefaults(suiteName: UserDefaults.globalDomain)
        return globalDefaults?.object(forKey: "com.apple.swipescrolldirection") as? Bool ?? true
    }

    @discardableResult
    func forceNaturalScrolling() -> Bool {
        restoreInterruptedOverrideIfNeeded()

        let originalValue = currentNaturalScrolling()
        self.originalValue = originalValue
        defaults.set(originalValue, forKey: Keys.originalValue)
        defaults.set(ProcessInfo.processInfo.processIdentifier, forKey: Keys.ownerPID)
        defaults.set(true, forKey: Keys.overrideActive)
        defaults.synchronize()

        guard setGlobalNaturalScrolling(true) else {
            clearRecoveryState()
            self.originalValue = nil
            return false
        }
        return true
    }

    func restoreOriginalIfNeeded() {
        guard ownsActiveOverride else {
            originalValue = nil
            return
        }

        let value = originalValue ?? defaults.bool(forKey: Keys.originalValue)
        if setGlobalNaturalScrolling(value) {
            clearRecoveryState()
            originalValue = nil
        }
    }

    private var ownsActiveOverride: Bool {
        guard defaults.bool(forKey: Keys.overrideActive) else {
            return false
        }
        return defaults.integer(forKey: Keys.ownerPID) == Int(ProcessInfo.processInfo.processIdentifier)
    }

    private func restoreInterruptedOverrideIfNeeded() {
        guard defaults.bool(forKey: Keys.overrideActive) else {
            return
        }

        let ownerPID = pid_t(defaults.integer(forKey: Keys.ownerPID))
        guard ownerPID <= 0 || !isProcessRunning(ownerPID) else {
            return
        }

        let originalValue = defaults.bool(forKey: Keys.originalValue)
        if setGlobalNaturalScrolling(originalValue) {
            clearRecoveryState()
        }
    }

    private func isProcessRunning(_ pid: pid_t) -> Bool {
        if kill(pid, 0) == 0 {
            return true
        }
        return errno == EPERM
    }

    private func clearRecoveryState() {
        defaults.removeObject(forKey: Keys.overrideActive)
        defaults.removeObject(forKey: Keys.originalValue)
        defaults.removeObject(forKey: Keys.ownerPID)
        defaults.synchronize()
    }

    @discardableResult
    private func setGlobalNaturalScrolling(_ enabled: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "-g", "com.apple.swipescrolldirection", "-bool", enabled ? "true" : "false"]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
