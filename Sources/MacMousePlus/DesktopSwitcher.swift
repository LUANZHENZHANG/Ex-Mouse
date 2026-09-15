import AppKit
import CoreGraphics
import Foundation

enum SystemShortcutScript {
    enum Action: Equatable {
        case previousDesktop
        case nextDesktop
        case zoomIn
        case zoomOut
    }

    static func source(for action: Action) -> String {
        let command: String
        switch action {
        case .previousDesktop:
            command = "key code 123 using control down"
        case .nextDesktop:
            command = "key code 124 using control down"
        case .zoomIn:
            command = "key code 24 using {command down, shift down}"
        case .zoomOut:
            command = "key code 27 using command down"
        }

        return """
        tell application "System Events"
            \(command)
        end tell
        """
    }
}

@MainActor
final class DesktopSwitcher {
    enum Direction {
        case previous
        case next

        var action: SystemShortcutScript.Action {
            switch self {
            case .previous: .previousDesktop
            case .next: .nextDesktop
            }
        }
    }

    private let onAutomationFailure: (String) -> Void
    private var isShortcutInFlight = false

    init(onAutomationFailure: @escaping (String) -> Void = { _ in }) {
        self.onAutomationFailure = onAutomationFailure
    }

    func stop() {
        isShortcutInFlight = false
    }

    @discardableResult
    func switchDesktop(_ direction: Direction) -> Bool {
        send(direction.action)
    }

    @discardableResult
    func zoomPage(in direction: ZoomDirection) -> Bool {
        send(direction.action)
    }

    enum ZoomDirection: Equatable {
        case `in`
        case out

        var action: SystemShortcutScript.Action {
            switch self {
            case .in: .zoomIn
            case .out: .zoomOut
            }
        }
    }

    @discardableResult
    private func send(_ action: SystemShortcutScript.Action) -> Bool {
        guard !isShortcutInFlight else {
            return false
        }

        isShortcutInFlight = true
        defer {
            isShortcutInFlight = false
        }

        guard let script = NSAppleScript(source: SystemShortcutScript.source(for: action)) else {
            onAutomationFailure("无法创建系统快捷键请求")
            return false
        }

        var error: NSDictionary?
        _ = script.executeAndReturnError(&error)
        guard error == nil else {
            onAutomationFailure("请允许顺鼠控制 System Events 后重试")
            return false
        }
        return true
    }
}
