import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let settings = SettingsStore()
    private lazy var scrollController = ScrollController { [weak self] in
        self?.refreshMenu()
    }
    private lazy var gestureController = GestureController(settings: settings) { [weak self] in
        self?.refreshMenu()
    }
    private let detailsWindowController = DetailsWindowController()
    private var permissionPollTimer: Timer?

    private var permissionActionItem: NSMenuItem?
    private var permissionStatusItem: NSMenuItem?
    private var scrollStatusItem: NSMenuItem?
    private var gestureStatusItem: NSMenuItem?
    private var debugStatusItem: NSMenuItem?
    private var gestureDebugStatusItem: NSMenuItem?
    private var scrollToggleItem: NSMenuItem?
    private var middleGestureToggleItem: NSMenuItem?
    private var shortcutToggleItem: NSMenuItem?
    private var settingsSubmenuItem: NSMenuItem?
    private var debugSubmenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        if PermissionManager.hasAccessibilityPermission {
            activateEnabledFeatures()
        } else {
            requestAccessibilityPermission(nil)
        }
        refreshMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionPollTimer?.invalidate()
        scrollController.stop()
        gestureController.stop()
    }

    @objc
    private func requestAccessibilityPermission(_ sender: Any?) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        PermissionManager.promptForAccessibilityIfNeeded()
        startPermissionPolling()
    }

    @objc
    private func repairAccessibilityPermission(_ sender: Any?) {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
        scrollController.stop()
        gestureController.stop()

        guard PermissionManager.resetAccessibilityPermission() else {
            showPermissionRepairError()
            return
        }

        PermissionManager.promptForAccessibilityIfNeeded()
        openAccessibilitySettings(nil)
        startPermissionPolling()
        refreshMenu()
    }

    @objc
    private func openAccessibilitySettings(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc
    private func toggleScroll(_ sender: Any?) {
        settings.scrollEnabled.toggle()
        applyScrollSetting()
        refreshMenu()
    }

    @objc
    private func toggleMiddleGestures(_ sender: Any?) {
        settings.middleGestureEnabled.toggle()
        applyGestureSetting()
        refreshMenu()
    }

    @objc
    private func toggleShortcuts(_ sender: Any?) {
        settings.shortcutEnabled.toggle()
        applyGestureSetting()
        refreshMenu()
    }

    @objc
    private func showDetails(_ sender: Any?) {
        detailsWindowController.show()
    }

    @objc
    private func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "顺鼠")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        }
        item.button?.toolTip = "顺鼠 Ex-Mouse"
        item.menu = NSMenu()
        statusItem = item

        permissionStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        permissionStatusItem?.isEnabled = false
        let permissionActionItem = NSMenuItem(
            title: "开启或修复辅助功能权限…",
            action: #selector(repairAccessibilityPermission(_:)),
            keyEquivalent: ""
        )
        permissionActionItem.target = self
        self.permissionActionItem = permissionActionItem
        scrollStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        scrollStatusItem?.isEnabled = false
        gestureStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        gestureStatusItem?.isEnabled = false
        debugStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        debugStatusItem?.isEnabled = false
        gestureDebugStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        gestureDebugStatusItem?.isEnabled = false

        let scrollToggleItem = NSMenuItem(
            title: "启用滚轮独立滚动方向",
            action: #selector(toggleScroll(_:)),
            keyEquivalent: ""
        )
        scrollToggleItem.target = self
        self.scrollToggleItem = scrollToggleItem

        let middleGestureToggleItem = NSMenuItem(
            title: "启用中键+手势功能",
            action: #selector(toggleMiddleGestures(_:)),
            keyEquivalent: ""
        )
        middleGestureToggleItem.target = self
        self.middleGestureToggleItem = middleGestureToggleItem

        let shortcutToggleItem = NSMenuItem(
            title: "启用中键侧键快捷键",
            action: #selector(toggleShortcuts(_:)),
            keyEquivalent: ""
        )
        shortcutToggleItem.target = self
        self.shortcutToggleItem = shortcutToggleItem

        let settingsMenu = NSMenu(title: "设置")
        let debugMenu = NSMenu(title: "调试")

        let requestPermissionItem = NSMenuItem(
            title: "申请并检查辅助功能权限",
            action: #selector(requestAccessibilityPermission(_:)),
            keyEquivalent: ""
        )
        requestPermissionItem.target = self

        let openAccessibilitySettingsItem = NSMenuItem(
            title: "打开辅助功能设置",
            action: #selector(openAccessibilitySettings(_:)),
            keyEquivalent: ""
        )
        openAccessibilitySettingsItem.target = self

        let repairAccessibilityItem = NSMenuItem(
            title: "重置并修复辅助功能授权…",
            action: #selector(repairAccessibilityPermission(_:)),
            keyEquivalent: ""
        )
        repairAccessibilityItem.target = self

        settingsMenu.items = [
            scrollToggleItem,
            middleGestureToggleItem,
            shortcutToggleItem,
        ]
        let settingsSubmenuItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        item.menu?.setSubmenu(settingsMenu, for: settingsSubmenuItem)
        self.settingsSubmenuItem = settingsSubmenuItem

        debugMenu.items = [
            debugStatusItem!,
            gestureDebugStatusItem!,
            .separator(),
            requestPermissionItem,
            repairAccessibilityItem,
            openAccessibilitySettingsItem,
        ]
        let debugSubmenuItem = NSMenuItem(title: "调试", action: nil, keyEquivalent: "")
        item.menu?.setSubmenu(debugMenu, for: debugSubmenuItem)
        self.debugSubmenuItem = debugSubmenuItem

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        let detailsItem = NSMenuItem(title: "详情…", action: #selector(showDetails(_:)), keyEquivalent: "")
        detailsItem.target = self
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"

        item.menu?.items = [
            NSMenuItem(title: "顺鼠 Ex-Mouse \(version)", action: nil, keyEquivalent: ""),
            .separator(),
            permissionActionItem,
            permissionStatusItem!,
            scrollStatusItem!,
            gestureStatusItem!,
            .separator(),
            settingsSubmenuItem,
            debugSubmenuItem,
            detailsItem,
            .separator(),
            quitItem,
        ]
    }

    private func refreshMenu() {
        let hasPermission = PermissionManager.hasAccessibilityPermission
        permissionActionItem?.isHidden = hasPermission
        permissionStatusItem?.title = hasPermission
            ? "辅助功能权限：已开启"
            : "辅助功能权限：未开启"
        scrollStatusItem?.title = !settings.scrollEnabled
            ? "滚动功能：已关闭"
            : scrollController.isListening
            ? "滚动监听：已就绪"
            : "滚动监听：创建失败"
        gestureStatusItem?.title = !settings.gestureListenerEnabled
            ? "鼠标功能：已关闭"
            : gestureController.isListening
            ? "鼠标监听：已就绪"
            : "鼠标监听：创建失败"
        debugStatusItem?.title = "调试：" + scrollController.backendName + " | " + scrollController.lastDebugMessage
        gestureDebugStatusItem?.title = "手势：" + gestureController.lastDebugMessage
        scrollToggleItem?.state = settings.scrollEnabled ? .on : .off
        middleGestureToggleItem?.state = settings.middleGestureEnabled ? .on : .off
        shortcutToggleItem?.state = settings.shortcutEnabled ? .on : .off
        settingsSubmenuItem?.title = "设置"
        debugSubmenuItem?.title = "调试"
    }

    private func applyScrollSetting() {
        if settings.scrollEnabled {
            scrollController.start()
        } else {
            scrollController.stop()
        }
    }

    private func applyGestureSetting() {
        if settings.gestureListenerEnabled {
            if gestureController.isListening {
                gestureController.reloadSettings()
            } else {
                gestureController.start()
            }
        } else {
            gestureController.stop()
        }
    }

    private func startPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(checkPermissionStatus(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    @objc
    private func checkPermissionStatus(_ timer: Timer) {
        guard PermissionManager.hasAccessibilityPermission else {
            refreshMenu()
            return
        }

        timer.invalidate()
        permissionPollTimer = nil
        activateEnabledFeatures()
        refreshMenu()
    }

    private func activateEnabledFeatures() {
        applyScrollSetting()
        applyGestureSetting()
    }

    private func showPermissionRepairError() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "无法自动修复辅助功能授权"
        alert.informativeText = "请在“系统设置 → 隐私与安全性 → 辅助功能”中删除旧的顺鼠条目，然后重新打开顺鼠。"
        alert.addButton(withTitle: "打开辅助功能设置")
        alert.runModal()
        openAccessibilitySettings(nil)
    }
}
