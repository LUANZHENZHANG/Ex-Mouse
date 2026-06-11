import CoreGraphics
import Foundation

final class DesktopSwitcher {
    enum Direction {
        case previous
        case next

        var gestureValue: Double {
            switch self {
            case .previous: -1
            case .next: 1
            }
        }

        var arrowKeyCode: CGKeyCode {
            switch self {
            case .previous: 123
            case .next: 124
            }
        }
    }

    private enum DockSwipe {
        static let lastVerifiedMacOSMajorVersion = 26
        static let steps = 16
        static let frameInterval = DispatchTimeInterval.milliseconds(16)
        static let totalProgress = 0.25
        static let eventType = CGEventField(rawValue: 55)!
        static let hidType = CGEventField(rawValue: 110)!
        static let motion = CGEventField(rawValue: 123)!
        static let progress = CGEventField(rawValue: 124)!
        static let velocityX = CGEventField(rawValue: 129)!
        static let velocityY = CGEventField(rawValue: 130)!
        static let phase = CGEventField(rawValue: 132)!
    }

    private var timer: DispatchSourceTimer?

    func stop() {
        timer?.cancel()
        timer = nil
    }

    @discardableResult
    func switchDesktop(_ direction: Direction) -> Bool {
        guard timer == nil else {
            return false
        }

        guard supportsDockSwipe,
              postDockSwipeEvent(phase: 1, progress: 0, direction: direction) else {
            return postKeyboardShortcut(direction)
        }

        var step = 0
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: DockSwipe.frameInterval)
        timer.setEventHandler { [weak self, weak timer] in
            guard let self, let timer else {
                return
            }

            step += 1
            let linearProgress = Double(step) / Double(DockSwipe.steps)
            let easedProgress = linearProgress * linearProgress * (3 - 2 * linearProgress)
            let progress = DockSwipe.totalProgress * easedProgress

            guard self.postDockSwipeEvent(phase: 2, progress: progress, direction: direction) else {
                timer.cancel()
                self.timer = nil
                _ = self.postKeyboardShortcut(direction)
                return
            }

            if step >= DockSwipe.steps {
                _ = self.postDockSwipeEvent(
                    phase: 4,
                    progress: DockSwipe.totalProgress,
                    direction: direction
                )
                timer.cancel()
                self.timer = nil
            }
        }
        self.timer = timer
        timer.resume()
        return true
    }

    private var supportsDockSwipe: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion <= DockSwipe.lastVerifiedMacOSMajorVersion
    }

    private func postDockSwipeEvent(phase: Int64, progress: Double, direction: Direction) -> Bool {
        guard let event = CGEvent(source: nil) else {
            return false
        }

        let gestureValue = direction.gestureValue
        event.setIntegerValueField(DockSwipe.eventType, value: 30)
        event.setIntegerValueField(DockSwipe.hidType, value: 23)
        event.setIntegerValueField(DockSwipe.phase, value: phase)
        event.setIntegerValueField(DockSwipe.motion, value: 1)
        event.setDoubleValueField(DockSwipe.progress, value: gestureValue * progress)
        event.setDoubleValueField(DockSwipe.velocityX, value: 0)
        event.setDoubleValueField(DockSwipe.velocityY, value: 0)
        event.post(tap: .cgSessionEventTap)
        return true
    }

    private func postKeyboardShortcut(_ direction: Direction) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: direction.arrowKeyCode,
                  keyDown: true
              ),
              let keyUp = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: direction.arrowKeyCode,
                  keyDown: false
              ) else {
            return false
        }

        keyDown.flags = .maskControl
        keyUp.flags = .maskControl
        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
        return true
    }
}
