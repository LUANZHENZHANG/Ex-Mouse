import Foundation

final class SettingsStore {
    private enum Keys {
        static let schemaVersion = "settingsSchemaVersion"
        static let scrollEnabled = "scrollEnabled"
        static let legacyGesturesEnabled = "gesturesEnabled"
        static let middleGestureEnabled = "middleButtonGesturesEnabled"
        static let shortcutEnabled = "sideButtonsEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        migrateLegacySettingsIfNeeded()
        defaults.register(defaults: [
            Keys.scrollEnabled: true,
            Keys.middleGestureEnabled: true,
            Keys.shortcutEnabled: true,
        ])
    }

    var scrollEnabled: Bool {
        get { defaults.bool(forKey: Keys.scrollEnabled) }
        set { defaults.set(newValue, forKey: Keys.scrollEnabled) }
    }

    var middleGestureEnabled: Bool {
        get { defaults.bool(forKey: Keys.middleGestureEnabled) }
        set { defaults.set(newValue, forKey: Keys.middleGestureEnabled) }
    }

    var shortcutEnabled: Bool {
        get { defaults.bool(forKey: Keys.shortcutEnabled) }
        set { defaults.set(newValue, forKey: Keys.shortcutEnabled) }
    }

    var gestureListenerEnabled: Bool {
        middleGestureEnabled || shortcutEnabled
    }

    private func migrateLegacySettingsIfNeeded() {
        guard defaults.integer(forKey: Keys.schemaVersion) < 2 else {
            return
        }

        if defaults.object(forKey: Keys.legacyGesturesEnabled) as? Bool == false {
            defaults.set(false, forKey: Keys.middleGestureEnabled)
            defaults.set(false, forKey: Keys.shortcutEnabled)
        }
        defaults.set(2, forKey: Keys.schemaVersion)
    }
}
