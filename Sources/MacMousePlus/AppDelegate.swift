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

    private var permissionStatusItem: NSMenuItem?
    private var scrollStatusItem: NSMenuItem?
    private var gestureStatusItem: NSMenuItem?
    private var debugStatusItem: NSMenuItem?
    private var gestureDebugStatusItem: NSMenuItem?
    private var scrollToggleItem: NSMenuItem?
    private var gestureMasterToggleItem: NSMenuItem?
    private var gesturesToggleItem: NSMenuItem?
    private var sideButtonsToggleItem: NSMenuItem?
    private var statusSubmenuItem: NSMenuItem?
    private var settingsSubmenuItem: NSMenuItem?
    private var debugSubmenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        requestAccessibilityPermission(nil)
        applyScrollSetting()
        applyGestureSetting()
        refreshMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        scrollController.stop()
        gestureController.stop()
    }

    @objc
    private func requestAccessibilityPermission(_ sender: Any?) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        PermissionManager.promptForAccessibilityIfNeeded()
        refreshMenu()
    }

    @objc
    private func openAccessibilitySettings(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc
    private func openInputMonitoringSettings(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
    }

    @objc
    private func openAutomationSettings(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }

    @objc
    private func toggleScroll(_ sender: Any?) {
        settings.scrollEnabled.toggle()
        applyScrollSetting()
        refreshMenu()
    }

    @objc
    private func toggleGestures(_ sender: Any?) {
        settings.gesturesEnabled.toggle()
        applyGestureSetting()
        refreshMenu()
    }

    @objc
    private func toggleMiddleGestures(_ sender: Any?) {
        settings.middleButtonGesturesEnabled.toggle()
        gestureController.reloadSettings()
        refreshMenu()
    }

    @objc
    private func toggleSideButtons(_ sender: Any?) {
        settings.sideButtonsEnabled.toggle()
        gestureController.reloadSettings()
        refreshMenu()
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
        scrollStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        scrollStatusItem?.isEnabled = false
        gestureStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        gestureStatusItem?.isEnabled = false
        debugStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        debugStatusItem?.isEnabled = false
        gestureDebugStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        gestureDebugStatusItem?.isEnabled = false

        let scrollToggleItem = NSMenuItem(
            title: "启用独立滚动方向",
            action: #selector(toggleScroll(_:)),
            keyEquivalent: ""
        )
        scrollToggleItem.target = self
        self.scrollToggleItem = scrollToggleItem

        let gestureMasterToggleItem = NSMenuItem(
            title: "启用手势功能",
            action: #selector(toggleGestures(_:)),
            keyEquivalent: ""
        )
        gestureMasterToggleItem.target = self
        self.gestureMasterToggleItem = gestureMasterToggleItem

        let gesturesToggleItem = NSMenuItem(
            title: "启用中键滑动手势",
            action: #selector(toggleMiddleGestures(_:)),
            keyEquivalent: ""
        )
        gesturesToggleItem.target = self
        self.gesturesToggleItem = gesturesToggleItem

        let sideButtonsToggleItem = NSMenuItem(
            title: "启用侧键切换桌面",
            action: #selector(toggleSideButtons(_:)),
            keyEquivalent: ""
        )
        sideButtonsToggleItem.target = self
        self.sideButtonsToggleItem = sideButtonsToggleItem

        let statusMenu = NSMenu(title: "状态")
        statusMenu.items = [
            permissionStatusItem!,
            scrollStatusItem!,
            gestureStatusItem!,
        ]
        let statusSubmenuItem = NSMenuItem(title: "状态", action: nil, keyEquivalent: "")
        item.menu?.setSubmenu(statusMenu, for: statusSubmenuItem)
        self.statusSubmenuItem = statusSubmenuItem

        let settingsMenu = NSMenu(title: "设置")
        let debugMenu = NSMenu(title: "调试")

        let requestPermissionItem = NSMenuItem(
            title: "重新申请辅助功能权限",
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

        let openInputMonitoringSettingsItem = NSMenuItem(
            title: "打开输入监控设置",
            action: #selector(openInputMonitoringSettings(_:)),
            keyEquivalent: ""
        )
        openInputMonitoringSettingsItem.target = self

        let openAutomationSettingsItem = NSMenuItem(
            title: "打开自动化设置",
            action: #selector(openAutomationSettings(_:)),
            keyEquivalent: ""
        )
        openAutomationSettingsItem.target = self

        settingsMenu.items = [
            scrollToggleItem,
            gestureMasterToggleItem,
            gesturesToggleItem,
            sideButtonsToggleItem,
        ]
        let settingsSubmenuItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        item.menu?.setSubmenu(settingsMenu, for: settingsSubmenuItem)
        self.settingsSubmenuItem = settingsSubmenuItem

        debugMenu.items = [
            debugStatusItem!,
            gestureDebugStatusItem!,
            .separator(),
            requestPermissionItem,
            openAccessibilitySettingsItem,
            openInputMonitoringSettingsItem,
            openAutomationSettingsItem,
        ]
        let debugSubmenuItem = NSMenuItem(title: "调试", action: nil, keyEquivalent: "")
        item.menu?.setSubmenu(debugMenu, for: debugSubmenuItem)
        self.debugSubmenuItem = debugSubmenuItem

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self

        item.menu?.items = [
            NSMenuItem(title: "顺鼠 Ex-Mouse", action: nil, keyEquivalent: ""),
            .separator(),
            statusSubmenuItem,
            settingsSubmenuItem,
            debugSubmenuItem,
            .separator(),
            quitItem,
        ]
    }

    private func refreshMenu() {
        let hasPermission = PermissionManager.hasAccessibilityPermission
        permissionStatusItem?.title = hasPermission
            ? "辅助功能权限：已开启"
            : "辅助功能权限：未开启"
        scrollStatusItem?.title = !settings.scrollEnabled
            ? "滚动功能：已关闭"
            : scrollController.isListening
            ? "滚动监听：已就绪"
            : "滚动监听：创建失败"
        gestureStatusItem?.title = !settings.gesturesEnabled
            ? "手势功能：已关闭"
            : gestureController.isListening
            ? "手势监听：已就绪"
            : "手势监听：创建失败"
        debugStatusItem?.title = "调试：" + scrollController.backendName + " | " + scrollController.lastDebugMessage
        gestureDebugStatusItem?.title = "手势：" + gestureController.lastDebugMessage
        scrollToggleItem?.state = settings.scrollEnabled ? .on : .off
        gestureMasterToggleItem?.state = settings.gesturesEnabled ? .on : .off
        gesturesToggleItem?.state = settings.middleButtonGesturesEnabled ? .on : .off
        sideButtonsToggleItem?.state = settings.sideButtonsEnabled ? .on : .off
        statusSubmenuItem?.title = "状态"
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
        if settings.gesturesEnabled {
            gestureController.start()
        } else {
            gestureController.stop()
        }
    }
}
