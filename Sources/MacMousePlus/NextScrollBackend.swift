import AppKit
import Foundation
import CoreGraphics

final class NextScrollBackend: ScrollBackend {
    private enum Constants {
        static let syntheticMarker = Int64(0x4E58542D5343524C)
        static let touchWindowNs: UInt64 = 222_000_000
        static let mouseWindowNs: UInt64 = 333_000_000
    }

    private enum EventDeviceKind: String {
        case mouse = "鼠标"
        case trackpad = "触控板"
    }

    private enum ScrollPhase {
        case normal
        case start
        case momentum
        case end
    }

    private let systemScrollDirectionManager = SystemScrollDirectionManager()
    private var activeTap: CFMachPort?
    private var activeRunLoopSource: CFRunLoopSource?
    private var passiveTap: CFMachPort?
    private var passiveRunLoopSource: CFRunLoopSource?

    private var lastTouchTimeNs: UInt64 = 0
    private var touchingCount = 0
    private var lastSource: EventDeviceKind = .mouse

    private(set) var isListening = false
    private(set) var lastDebugMessage = "尚未处理滚动事件"
    let name = "Next"

    init(onStateChanged: @escaping () -> Void) {}

    func start() {
        stop()
        systemScrollDirectionManager.forceNaturalScrolling()
        createPassiveTapIfNeeded()
        createActiveTapIfNeeded()
        isListening = activeTap != nil && passiveTap != nil
        if isListening {
            lastDebugMessage = "滚动后端已就绪"
        }
    }

    func stop() {
        if let tap = activeTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = activeRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = passiveTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = passiveRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        activeTap = nil
        activeRunLoopSource = nil
        passiveTap = nil
        passiveRunLoopSource = nil
        lastTouchTimeNs = 0
        touchingCount = 0
        lastSource = .mouse
        systemScrollDirectionManager.restoreOriginalIfNeeded()
        isListening = false
        lastDebugMessage = "滚动后端已停止"
    }

    private func createPassiveTapIfNeeded() {
        guard let gestureType = CGEventType(rawValue: UInt32(NSEvent.EventType.gesture.rawValue)) else {
            lastDebugMessage = "无法识别 gesture 事件类型"
            return
        }
        let events = CGEventMask(1 << gestureType.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            let backend = Unmanaged<NextScrollBackend>.fromOpaque(refcon!).takeUnretainedValue()
            return backend.handlePassiveEvent(type: type, event: event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: events,
            callback: callback,
            userInfo: refcon
        ) else {
            lastDebugMessage = "被动手势监听创建失败"
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        passiveTap = tap
        passiveRunLoopSource = source
    }

    private func createActiveTapIfNeeded() {
        let events: CGEventMask =
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            let backend = Unmanaged<NextScrollBackend>.fromOpaque(refcon!).takeUnretainedValue()
            return backend.handleActiveEvent(proxy: proxy, type: type, event: event)
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
            lastDebugMessage = "滚动监听创建失败"
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        activeTap = tap
        activeRunLoopSource = source
    }

    private func handlePassiveEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let gestureType = CGEventType(rawValue: UInt32(NSEvent.EventType.gesture.rawValue)),
              type == gestureType,
              let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passUnretained(event)
        }

        let touching = nsEvent.touches(matching: .touching, in: nil).count
        if touching >= 2 {
            touchingCount = max(touchingCount, touching)
            lastTouchTimeNs = DispatchTime.now().uptimeNanoseconds
        }
        return Unmanaged.passUnretained(event)
    }

    private func handleActiveEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = activeTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            if let tap = passiveTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == Constants.syntheticMarker {
            return Unmanaged.passUnretained(event)
        }

        let source = classify(event)
        if source == .mouse {
            reverseMouseScroll(on: event)
            let dy = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
            let dx = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
            lastDebugMessage = "鼠标反转：dx=\(dx) dy=\(dy)"
        } else {
            let dy = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
            let dx = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
            lastDebugMessage = "触控板放行：dx=\(dx) dy=\(dy)"
        }
        return Unmanaged.passUnretained(event)
    }

    private func classify(_ event: CGEvent) -> EventDeviceKind {
        let now = DispatchTime.now().uptimeNanoseconds
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let phase = phaseForEvent(event)
        let touchElapsed = lastTouchTimeNs == 0 ? UInt64.max : now &- lastTouchTimeNs
        let touching = touchingCount
        touchingCount = 0

        let source: EventDeviceKind
        if !isContinuous {
            source = .mouse
        } else if touching >= 2 && touchElapsed < Constants.touchWindowNs {
            source = .trackpad
        } else if phase == .normal && touchElapsed > Constants.mouseWindowNs {
            source = .mouse
        } else {
            source = lastSource
        }

        lastSource = source
        return source
    }

    private func phaseForEvent(_ event: CGEvent) -> ScrollPhase {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return .normal
        }

        switch nsEvent.momentumPhase {
        case .began:
            return .start
        case .stationary, .changed, .mayBegin:
            return .momentum
        case .ended, .cancelled:
            return .end
        default:
            return .normal
        }
    }

    private func reverseMouseScroll(on event: CGEvent) {
        let axis1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let axis2 = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        let pointAxis1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let pointAxis2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        let fixedAxis1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let fixedAxis2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)

        if axis1 != 0 {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -axis1)
        }
        if axis2 != 0 {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -axis2)
        }
        if fixedAxis1 != 0 {
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedAxis1)
        }
        if pointAxis1 != 0 {
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointAxis1)
        }
        if fixedAxis2 != 0 {
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fixedAxis2)
        }
        if pointAxis2 != 0 {
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -pointAxis2)
        }
        event.setIntegerValueField(.eventSourceUserData, value: Constants.syntheticMarker)
    }
}
