import AppKit

@MainActor
final class DetailsWindowController: NSObject {
    private final class FlippedView: NSView {
        override var isFlipped: Bool { true }
    }

    private var detailsWindow: NSWindow?

    func show() {
        let window = detailsWindow ?? makeWindow()
        detailsWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "顺鼠 Ex-Mouse 详情"
        window.minSize = NSSize(width: 560, height: 620)
        window.isReleasedWhenClosed = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        documentView.addSubview(stack)

        let iconView = NSImageView()
        iconView.image = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 88),
            iconView.heightAnchor.constraint(equalToConstant: 88),
        ])

        let titleLabel = makeLabel("顺鼠 Ex-Mouse", font: .systemFont(ofSize: 28, weight: .semibold))
        let summaryLabel = makeLabel(
            "不联网，让鼠标和触控板一样丝滑",
            font: .systemFont(ofSize: 14),
            color: .secondaryLabelColor
        )

        let headerText = NSStackView(views: [titleLabel, summaryLabel])
        headerText.orientation = .vertical
        headerText.alignment = .leading
        headerText.spacing = 6

        let header = NSStackView(views: [iconView, headerText])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 18
        stack.addArrangedSubview(header)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"
        let informationGrid = NSGridView(views: [
            [makeMetadataLabel("作者"), makeValueLabel("Luanzhen")],
            [makeMetadataLabel("版本"), makeValueLabel(version)],
            [makeMetadataLabel("网址"), makeLinkButton("luanzhen.online/Ex-Mouse.html", action: #selector(openWebsite))],
            [makeMetadataLabel("邮箱"), makeLinkButton("zeliangzhang@gmail.com", action: #selector(openEmail))],
            [makeMetadataLabel("Telegram"), makeLinkButton("@luanzhen", action: #selector(openTelegram))],
        ])
        informationGrid.rowSpacing = 10
        informationGrid.columnSpacing = 18
        informationGrid.column(at: 0).width = 80
        stack.addArrangedSubview(informationGrid)

        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeSectionTitle("为什么做顺鼠"))

        let introduction = makeLabel(
            """
            我在 Mac 使用中发现一些小问题：Magic Mouse 不好用、普通鼠标在 Mac 上无法使用手势、滚轮方向也和触控板相反。

            我不愿意使用太复杂的 Mac 鼠标设置软件，所以让 Codex 设计了这个小工具。

            这个项目从前到后都是 Codex 帮我完成的。我自己用着挺好，所以分享给有同样需要的朋友；如果使用中有任何问题，请提醒我。谢谢！
            """,
            font: .systemFont(ofSize: 14),
            color: .labelColor
        )
        introduction.maximumNumberOfLines = 0
        introduction.lineBreakMode = .byWordWrapping
        introduction.preferredMaxLayoutWidth = 520
        stack.addArrangedSubview(introduction)

        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeSectionTitle("使用简介"))

        if let demoURL = Bundle.main.url(forResource: "ExMouseDemo", withExtension: "gif"),
           let demoImage = NSImage(contentsOf: demoURL) {
            let demoView = NSImageView()
            demoView.image = demoImage
            demoView.imageScaling = .scaleProportionallyUpOrDown
            demoView.animates = true
            demoView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                demoView.widthAnchor.constraint(equalToConstant: 520),
                demoView.heightAnchor.constraint(equalToConstant: 520),
            ])
            stack.addArrangedSubview(demoView)
        } else {
            stack.addArrangedSubview(
                makeLabel("演示动图未能加载。", font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
            )
        }

        let contentView = FlippedView()
        contentView.addSubview(scrollView)
        window.contentView = contentView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: documentView.trailingAnchor, constant: -40),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -32),
        ])

        return window
    }

    private func makeSectionTitle(_ title: String) -> NSTextField {
        makeLabel(title, font: .systemFont(ofSize: 18, weight: .semibold))
    }

    private func makeMetadataLabel(_ title: String) -> NSTextField {
        makeLabel(title, font: .systemFont(ofSize: 13, weight: .medium), color: .secondaryLabelColor)
    }

    private func makeValueLabel(_ value: String) -> NSTextField {
        makeLabel(value, font: .systemFont(ofSize: 13))
    }

    private func makeLabel(
        _ text: String,
        font: NSFont,
        color: NSColor = .labelColor
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.isSelectable = true
        return label
    }

    private func makeLinkButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.font = .systemFont(ofSize: 13)
        button.contentTintColor = .linkColor
        button.alignment = .left
        return button
    }

    private func makeSeparator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 520).isActive = true
        return separator
    }

    @objc
    private func openWebsite() {
        open("https://luanzhen.online/Ex-Mouse.html")
    }

    @objc
    private func openEmail() {
        open("mailto:zeliangzhang@gmail.com")
    }

    @objc
    private func openTelegram() {
        open("https://t.me/luanzhen")
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
