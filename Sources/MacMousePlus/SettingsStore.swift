import Foundation

final class SettingsStore {
    private enum Keys {
        static let scrollEnabled = "scrollEnabled"
        static let gesturesEnabled = "gesturesEnabled"
        static let middleButtonGesturesEnabled = "middleButtonGesturesEnabled"
        static let sideButtonsEnabled = "sideButtonsEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.scrollEnabled: true,
            Keys.gesturesEnabled: true,
            Keys.middleButtonGesturesEnabled: true,
            Keys.sideButtonsEnabled: true,
        ])
    }

    var scrollEnabled: Bool {
        get { defaults.bool(forKey: Keys.scrollEnabled) }
        set { defaults.set(newValue, forKey: Keys.scrollEnabled) }
    }

    var gesturesEnabled: Bool {
        get { defaults.bool(forKey: Keys.gesturesEnabled) }
        set { defaults.set(newValue, forKey: Keys.gesturesEnabled) }
    }

    var middleButtonGesturesEnabled: Bool {
        get { defaults.bool(forKey: Keys.middleButtonGesturesEnabled) }
        set { defaults.set(newValue, forKey: Keys.middleButtonGesturesEnabled) }
    }

    var sideButtonsEnabled: Bool {
        get { defaults.bool(forKey: Keys.sideButtonsEnabled) }
        set { defaults.set(newValue, forKey: Keys.sideButtonsEnabled) }
    }
}
