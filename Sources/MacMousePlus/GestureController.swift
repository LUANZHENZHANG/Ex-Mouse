import AppKit
import ApplicationServices
import CoreGraphics

final class GestureController {
    private enum Constants {
        static let horizontalTriggerDistance: CGFloat = 96
        static let verticalTriggerDistance: CGFloat = 56
        static let directionBias: CGFloat = 18
        static let middleClickMovementTolerance: CGFloat = 8
        static let dockSwipeSteps = 16
        static let dockSwipeFrameInterval = DispatchTimeInterval.milliseconds(16)
        static let dockSwipeProgress = 0.25
        static let dockSwipeVelocity = 0.0
        static let cgsEventTypeField = CGEventField(rawValue: 55)!
        static let gestureHIDTypeField = CGEventField(rawValue: 110)!
        static let swipeMotionField = CGEventField(rawValue: 123)!
        static let swipeProgressField = CGEventField(rawValue: 124)!
        static let swipeVelocityXField = CGEventField(rawValue: 129)!
        static let swipeVelocityYField = CGEventField(rawValue: 130)!
        static let gesturePhaseField = CGEventField(rawValue: 132)!
    }

    private enum GestureAction {
        case previousSpace
        case nextSpace
        case missionControl

        var description: String {
            switch self {
            case .previousSpace:
                return "Previous Desktop"
            case .nextSpace:
                return "Next Desktop"
            case .missionControl:
                return "Mission Control"
            }
        }
    }

    private struct GestureState {
        var downLocation: CGPoint
        var lastLocation: CGPoint
        var hasTriggered = false
    }

    private let settings: SettingsStore
    private let onStateChanged: () -> Void

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var trackingTimer: DispatchSourceTimer?
    private var desktopSwipeTimer: DispatchSourceTimer?
    private var gestureState: GestureState?
    private var gestureLockedUntilMouseUp = false
    private var lastMiddleClickTime: TimeInterval?
    private var swallowedOtherMouseUpButtons = Set<Int64>()
    private(set) var isListening = false
    private(set) var lastDebugMessage = "尚未收到事件"

    init(settings: SettingsStore, onStateChanged: @escaping () -> Void) {
        self.settings = settings
        self.onStateChanged = onStateChanged
    }

    func start() {
        stop()
        createListenersIfNeeded()
        onStateChanged()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        trackingTimer?.cancel()
        desktopSwipeTimer?.cancel()
        eventTap = nil
        runLoopSource = nil
        trackingTimer = nil
        desktopSwipeTimer = nil
        gestureState = nil
        gestureLockedUntilMouseUp = false
        lastMiddleClickTime = nil
        isListening = false
    }

    func reloadSettings() {
        if eventTap == nil {
            createListenersIfNeeded()
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: settings.gesturesEnabled)
        }
        onStateChanged()
    }

    private func createListenersIfNeeded() {
        createEventTapIfNeeded()
        isListening = eventTap != nil
    }

    private func createEventTapIfNeeded() {
        guard eventTap == nil else {
            return
        }

        let events: CGEventMask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            let controller = Unmanaged<GestureController>.fromOpaque(refcon!).takeUnretainedValue()
            return controller.handleEvent(proxy: proxy, type: type, event: event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: events,
            callback: callback,
            userInfo: refcon
        ) else {
            lastDebugMessage = "监听创建失败，请开启辅助功能权限"
            isListening = false
            onStateChanged()
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: settings.gesturesEnabled)

        eventTap = tap
        runLoopSource = source
        isListening = true
        lastDebugMessage = "辅助功能监听已建立"
        onStateChanged()
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: settings.gesturesEnabled)
            }
            return Unmanaged.passRetained(event)
        }

        guard settings.gesturesEnabled, PermissionManager.hasAccessibilityPermission else {
            return Unmanaged.passRetained(event)
        }

        switch type {
        case .otherMouseDown:
            let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
            if settings.sideButtonsEnabled, let action = sideButtonAction(for: buttonNumber) {
                swallowedOtherMouseUpButtons.insert(buttonNumber)
                trigger(action)
                return nil
            }
            guard buttonNumber == 2, settings.middleButtonGesturesEnabled else {
                return Unmanaged.passRetained(event)
            }
            gestureLockedUntilMouseUp = false
            let location = NSEvent.mouseLocation
            beginTracking(at: location, source: "底层监听")
            updateDebug("收到中键按下")
            return nil

        case .otherMouseDragged:
            guard event.getIntegerValueField(.mouseEventButtonNumber) == 2, settings.middleButtonGesturesEnabled else {
                return Unmanaged.passRetained(event)
            }
            guard !gestureLockedUntilMouseUp else {
                return nil
            }
            guard var state = gestureState else {
                return Unmanaged.passRetained(event)
            }
            state.lastLocation = NSEvent.mouseLocation
            gestureState = state

            if let action = detectAction(from: state) {
                commitTrigger(action, state: state)
            }
            return gestureLockedUntilMouseUp ? nil : Unmanaged.passRetained(event)

        case .otherMouseUp:
            let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
            if swallowedOtherMouseUpButtons.remove(buttonNumber) != nil {
                return nil
            }
            guard buttonNumber == 2, settings.middleButtonGesturesEnabled else {
                return Unmanaged.passRetained(event)
            }
            defer { endTracking() }
            gestureLockedUntilMouseUp = false
            updateDebug("收到中键抬起", transient: true)
            guard let state = gestureState else {
                return Unmanaged.passRetained(event)
            }
            if state.hasTriggered {
                lastMiddleClickTime = nil
                return nil
            }
            handleMiddleClick(state)
            return nil

        default:
            return Unmanaged.passRetained(event)
        }
    }

    private func detectAction(from state: GestureState) -> GestureAction? {
        let dx = state.lastLocation.x - state.downLocation.x
        let dy = state.lastLocation.y - state.downLocation.y

        if abs(dx) >= Constants.horizontalTriggerDistance, abs(dx) > abs(dy) + Constants.directionBias {
            updateDebug(dx < 0 ? "中键识别为左滑" : "中键识别为右滑")
            return dx < 0 ? .nextSpace : .previousSpace
        }

        if abs(dy) >= Constants.verticalTriggerDistance,
           abs(dy) > abs(dx) + Constants.directionBias {
            updateDebug("中键识别为纵向滑动")
            return .missionControl
        }

        updateDebug("中键拖动中：dx=\(Int(dx)) dy=\(Int(dy))")
        return nil
    }

    private func trigger(_ action: GestureAction) {
        updateDebug("触发动作：\(action.description)")
        switch action {
        case .previousSpace:
            triggerDesktopSwipe(direction: -1)
        case .nextSpace:
            triggerDesktopSwipe(direction: 1)
        case .missionControl:
            openMissionControl()
        }
    }

    private func openMissionControl() {
        let missionControlURL = URL(fileURLWithPath: "/System/Applications/Mission Control.app")
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: missionControlURL, configuration: configuration, completionHandler: nil)
    }

    private func triggerDesktopSwipe(direction: Double) {
        guard desktopSwipeTimer == nil else {
            return
        }

        postDesktopSwipeEvent(phase: 1, progress: 0, velocity: 0, direction: direction)

        var step = 0
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: Constants.dockSwipeFrameInterval)
        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }

            step += 1
            let linearProgress = Double(step) / Double(Constants.dockSwipeSteps)
            let easedProgress = linearProgress * linearProgress * (3 - 2 * linearProgress)
            let progress = Constants.dockSwipeProgress * easedProgress
            postDesktopSwipeEvent(
                phase: 2,
                progress: progress,
                velocity: Constants.dockSwipeVelocity,
                direction: direction
            )

            if step >= Constants.dockSwipeSteps {
                postDesktopSwipeEvent(
                    phase: 4,
                    progress: Constants.dockSwipeProgress,
                    velocity: Constants.dockSwipeVelocity,
                    direction: direction
                )
                timer.cancel()
                desktopSwipeTimer = nil
            }
        }
        desktopSwipeTimer = timer
        timer.resume()
    }

    private func postDesktopSwipeEvent(phase: Int64, progress: Double, velocity: Double, direction: Double) {
        guard let event = CGEvent(source: nil) else {
            updateDebug("动作发送失败：无法创建桌面切换事件")
            desktopSwipeTimer?.cancel()
            desktopSwipeTimer = nil
            return
        }

        event.setIntegerValueField(Constants.cgsEventTypeField, value: 30)
        event.setIntegerValueField(Constants.gestureHIDTypeField, value: 23)
        event.setIntegerValueField(Constants.gesturePhaseField, value: phase)
        event.setIntegerValueField(Constants.swipeMotionField, value: 1)
        event.setDoubleValueField(Constants.swipeProgressField, value: direction * progress)
        event.setDoubleValueField(Constants.swipeVelocityXField, value: direction * velocity)
        event.setDoubleValueField(Constants.swipeVelocityYField, value: direction * velocity)
        event.post(tap: .cgSessionEventTap)
    }

    private func handleMiddleClick(_ state: GestureState) {
        let movement = hypot(
            state.lastLocation.x - state.downLocation.x,
            state.lastLocation.y - state.downLocation.y
        )
        guard movement <= Constants.middleClickMovementTolerance else {
            lastMiddleClickTime = nil
            updateDebug("中键移动未形成手势")
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        if let lastMiddleClickTime,
           now - lastMiddleClickTime <= NSEvent.doubleClickInterval {
            self.lastMiddleClickTime = nil
            updateDebug("中键双击：调度中心")
            openMissionControl()
        } else {
            lastMiddleClickTime = now
            updateDebug("收到第一次中键点击")
        }
    }

    private func beginTracking(at location: CGPoint, source: String) {
        trackingTimer?.cancel()
        gestureState = GestureState(downLocation: location, lastLocation: location)
        gestureLockedUntilMouseUp = false

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))
        timer.setEventHandler { [weak self] in
            self?.pollMouseLocation(source: source)
        }
        timer.resume()
        trackingTimer = timer
    }

    private func endTracking() {
        trackingTimer?.cancel()
        trackingTimer = nil
        gestureState = nil
        gestureLockedUntilMouseUp = false
    }

    private func pollMouseLocation(source: String) {
        guard var state = gestureState else {
            return
        }

        let currentLocation = NSEvent.mouseLocation
        state.lastLocation = currentLocation
        gestureState = state

        if !gestureLockedUntilMouseUp, let action = detectAction(from: state) {
            updateDebug("\(source)：轮询识别成功")
            commitTrigger(action, state: state)
        }
    }

    private func commitTrigger(_ action: GestureAction, state: GestureState) {
        guard !gestureLockedUntilMouseUp else {
            return
        }

        var updatedState = state
        updatedState.hasTriggered = true
        gestureState = updatedState
        gestureLockedUntilMouseUp = true
        trackingTimer?.cancel()
        trackingTimer = nil
        trigger(action)
    }

    private func updateDebug(_ message: String, transient: Bool = false) {
        if transient, isMeaningfulDebug(lastDebugMessage) {
            onStateChanged()
            return
        }
        lastDebugMessage = message
        onStateChanged()
    }

    private func isMeaningfulDebug(_ message: String) -> Bool {
        message.contains("识别为") || message.contains("触发动作") || message.contains("轮询识别成功")
    }

    private func sideButtonAction(for buttonNumber: Int64) -> GestureAction? {
        switch buttonNumber {
        case 3:
            updateDebug("侧键上：下一个桌面")
            return .nextSpace
        case 4:
            updateDebug("侧键下：上一个桌面")
            return .previousSpace
        default:
            return nil
        }
    }
}
