import ServiceManagement

enum LoginItemManager {
    enum State {
        case enabled
        case requiresApproval
        case unavailable
    }

    static func ensureRegistered() -> State {
        let service = SMAppService.mainApp

        if service.status == .notRegistered {
            do {
                try service.register()
            } catch {
                return .unavailable
            }
        }

        return state
    }

    static var state: State {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        default:
            return .unavailable
        }
    }

    static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
