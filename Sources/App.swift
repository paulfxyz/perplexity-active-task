import AppKit
import WebKit

private let homeURL = URL(string: "https://www.perplexity.ai/computer/tasks?status=active")!
private let defaults: UserDefaults = {
    #if SCREENSHOT_BUILD
    return UserDefaults(suiteName: "com.paulfleury.activetask.screenshots")!
    #else
    return .standard
    #endif
}()

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate,
    WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, NSToolbarDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var statusItem: NSStatusItem!
    private var popups: [NSWindow] = []
    private var settingsButton: NSButton!
    private var progress: NSProgressIndicator!
    private var errorLabel: NSTextField!
    private var preferencesWindow: NSWindow?
    private var preferenceControls: [Int: NSControl] = [:]
    #if SCREENSHOT_BUILD
    private var screenshotDirectory: URL?
    #endif
    private var floatOnTop: Bool {
        get { defaults.bool(forKey: "floatOnTop") }
        set { defaults.set(newValue, forKey: "floatOnTop"); applyWindowBehavior() }
    }
    private var dimWhenInactive: Bool {
        get { defaults.bool(forKey: "dimWhenInactive") }
        set { defaults.set(newValue, forKey: "dimWhenInactive"); applyWindowBehavior() }
    }
    private var hideSidebar: Bool {
        get { defaults.bool(forKey: "hideSidebar") }
        set { defaults.set(newValue, forKey: "hideSidebar"); updateSidebar() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [
            "floatOnTop": true, "dimWhenInactive": false,
            "inactiveOpacity": 0.60, "hideSidebar": true, "zoom": 1.0
        ])
        defaults.set(WindowBehavior.normalizedInactiveOpacity(defaults.double(forKey: "inactiveOpacity")),
                     forKey: "inactiveOpacity")
        buildMenu()
        buildWindow()
        buildStatusItem()
        showWindow(nil)
        #if SCREENSHOT_BUILD
        if let index = CommandLine.arguments.firstIndex(of: "--screenshots"),
           CommandLine.arguments.count > index + 1 {
            screenshotDirectory = URL(fileURLWithPath: CommandLine.arguments[index + 1])
            guard let fixture = Bundle.main.url(forResource: "ScreenshotFixture", withExtension: "html") else {
                fatalError("Screenshot fixture missing")
            }
            webView.loadFileURL(fixture, allowingReadAccessTo: fixture.deletingLastPathComponent())
            return
        }
        #endif
        webView.load(URLRequest(url: homeURL))
    }

    private func buildWindow() {
        let configuration = WKWebViewConfiguration()
        #if SCREENSHOT_BUILD
        configuration.websiteDataStore = .nonPersistent()
        #else
        configuration.websiteDataStore = .default()
        #endif
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        for resource in ["Cost", "CostDisplay"] {
            if let url = Bundle.main.url(forResource: resource, withExtension: "js"),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                configuration.userContentController.addUserScript(WKUserScript(
                    source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient))
            }
        }
        if let url = Bundle.main.url(forResource: "Sidebar", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            let enabled = hideSidebar ? "true" : "false"
            let script = "window.__activeTaskSidebarEnabled = \(enabled);\n" + source
            configuration.userContentController.addUserScript(WKUserScript(
                source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true,
                in: .defaultClient))
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.pageZoom = defaults.double(forKey: "zoom")

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 700),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Active Task"
        window.minSize = NSSize(width: 360, height: 360)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.center()
        window.setFrameAutosaveName("ActiveTaskWindow")
        window.tabbingMode = .disallowed

        let container = NSView()
        window.contentView = container
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        errorLabel = NSTextField(wrappingLabelWithString: "")
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.alignment = .center
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            errorLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        let toolbar = NSToolbar(identifier: "ActiveTaskToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact
        applyWindowBehavior()
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier("home"), NSToolbarItem.Identifier("reload"),
                .flexibleSpace, NSToolbarItem.Identifier("progress"), NSToolbarItem.Identifier("settings")]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: identifier)
        if identifier.rawValue == "progress" {
            progress = NSProgressIndicator()
            progress.style = .spinning
            progress.controlSize = .small
            progress.isDisplayedWhenStopped = false
            progress.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
            item.view = progress
            item.label = "Loading"
            return item
        }
        let symbols: [String: (String, String, Selector)] = [
            "home": ("list.bullet.rectangle", "Active tasks", #selector(goHome)),
            "reload": ("arrow.clockwise", "Reload", #selector(reload)),
            "settings": ("slider.horizontal.3", "Window settings", #selector(showSettings(_:)))
        ]
        guard let (symbol, label, action) = symbols[identifier.rawValue] else { return nil }
        let button = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: label)!,
                              target: self, action: action)
        button.bezelStyle = .texturedRounded
        button.toolTip = label
        button.setAccessibilityLabel(label)
        if identifier.rawValue == "settings" { settingsButton = button }
        item.view = button
        item.label = label
        return item
    }

    private func buildMenu() {
        let main = NSMenu()
        let app = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Active Task", action: #selector(about), keyEquivalent: "")
        addAction("Settings…", #selector(showPreferences), key: ",", to: appMenu)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Active Task", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Active Task", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = appMenu
        main.addItem(app)
        let edit = NSMenuItem()
        edit.title = "Edit"
        let editMenu = NSMenu(title: "Edit")
        for (title, selector, key) in [
            ("Undo", "undo:", "z"), ("Redo", "redo:", "Z"),
            ("Cut", "cut:", "x"), ("Copy", "copy:", "c"),
            ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")
        ] { editMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key) }
        edit.submenu = editMenu
        main.addItem(edit)
        let view = NSMenuItem()
        view.title = "View"
        let viewMenu = NSMenu(title: "View")
        addAction("Active tasks", #selector(goHome), key: "1", to: viewMenu)
        addAction("Organization Usage", #selector(goOrganization), key: "2", to: viewMenu)
        addAction("Reload", #selector(reload), key: "r", to: viewMenu)
        addAction("Open current page in browser", #selector(openInBrowser), key: "b", to: viewMenu)
        viewMenu.addItem(.separator())
        addAction("Zoom In", #selector(zoomIn), key: "+", to: viewMenu)
        addAction("Zoom Out", #selector(zoomOut), key: "-", to: viewMenu)
        addAction("Actual Size", #selector(zoomReset), key: "0", to: viewMenu)
        view.submenu = viewMenu
        main.addItem(view)
        let windowMenu = NSMenu(title: "Window")
        addAction("Show Active Task", #selector(showWindow(_:)), key: "", to: windowMenu)
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let windowItem = NSMenuItem()
        windowItem.title = "Window"
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu
    }

    private func addAction(_ title: String, _ action: Selector, key: String = "", to menu: NSMenu) {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "Active Task")
        statusItem.button?.toolTip = "Active Task"
        let menu = NSMenu()
        addAction("Show Active Task", #selector(showWindow(_:)), to: menu)
        addAction("Active tasks", #selector(goHome), to: menu)
        addAction("Organization Usage", #selector(goOrganization), to: menu)
        menu.addItem(.separator())
        addAction("Quit Active Task", #selector(NSApplication.terminate(_:)), to: menu)
        menu.items.last?.target = NSApp
        statusItem.menu = menu
    }

    @objc private func showSettings(_ sender: NSButton) {
        let menu = NSMenu()
        let floating = menu.addItem(withTitle: "Always on Top", action: #selector(toggleFloat), keyEquivalent: "")
        floating.target = self
        floating.state = floatOnTop ? .on : .off
        let dim = menu.addItem(withTitle: "Dim When Inactive", action: #selector(toggleDim), keyEquivalent: "")
        dim.target = self
        dim.state = dimWhenInactive ? .on : .off
        let opacity = NSMenuItem(title: "Inactive Opacity", action: nil, keyEquivalent: "")
        let levels = NSMenu()
        for percent in WindowBehavior.inactiveOpacityPercentages {
            let level = levels.addItem(withTitle: "\(percent)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            level.target = self
            level.tag = percent
            level.state = abs(defaults.double(forKey: "inactiveOpacity") - Double(percent) / 100) < 0.01 ? .on : .off
        }
        opacity.submenu = levels
        menu.addItem(opacity)
        addAction("Normal Window Behavior", #selector(useNormalBehavior), to: menu)
        addAction("Window Settings…", #selector(showPreferences), to: menu)
        menu.addItem(.separator())
        let sidebar = menu.addItem(withTitle: "Hide Website Sidebar", action: #selector(toggleSidebar), keyEquivalent: "")
        sidebar.target = self
        sidebar.state = hideSidebar ? .on : .off
        addAction("Open in Browser (Login Fallback)", #selector(openInBrowser), to: menu)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func toggleFloat() { floatOnTop.toggle() }
    @objc private func toggleDim() { dimWhenInactive.toggle() }
    @objc private func toggleSidebar() { hideSidebar.toggle() }
    @objc private func setOpacity(_ sender: NSMenuItem) {
        defaults.set(Double(sender.tag) / 100, forKey: "inactiveOpacity")
        dimWhenInactive = true
    }
    @objc private func useNormalBehavior() {
        floatOnTop = false
        dimWhenInactive = false
    }

    @objc private func showPreferences() {
        if let preferencesWindow = preferencesWindow {
            refreshPreferenceControls()
            preferencesWindow.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 450, height: 380),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "Window Settings"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 17
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: panel.contentView!.topAnchor, constant: 24)
        ])
        let title = NSTextField(labelWithString: "Stay visible. Stay out of the way.")
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        stack.addArrangedSubview(title)
        for (tag, label) in [(1, "Always on top"), (2, "Dim when inactive"), (3, "Hide website sidebar")] {
            let checkbox = NSButton(checkboxWithTitle: label, target: self, action: #selector(preferenceChanged(_:)))
            checkbox.tag = tag
            preferenceControls[tag] = checkbox
            stack.addArrangedSubview(checkbox)
        }
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 20
        row.addArrangedSubview(NSTextField(labelWithString: "Inactive opacity"))
        let levels = NSPopUpButton()
        levels.target = self
        levels.action = #selector(preferenceChanged(_:))
        levels.tag = 4
        for percent in WindowBehavior.inactiveOpacityPercentages {
            levels.addItem(withTitle: "\(percent)%")
            levels.lastItem?.tag = percent
        }
        row.addArrangedSubview(levels)
        preferenceControls[4] = levels
        stack.addArrangedSubview(row)
        let hint = NSTextField(wrappingLabelWithString:
            "Lower percentages are more transparent. Click the task window to restore full opacity. Dimming also starts when you open these settings.")
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .secondaryLabelColor
        hint.preferredMaxLayoutWidth = 394
        stack.addArrangedSubview(hint)
        let normal = NSButton(title: "Use Normal Window Behavior", target: self, action: #selector(resetPreferences))
        normal.bezelStyle = .rounded
        stack.addArrangedSubview(normal)
        preferencesWindow = panel
        refreshPreferenceControls()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    private func refreshPreferenceControls() {
        (preferenceControls[1] as? NSButton)?.state = floatOnTop ? .on : .off
        (preferenceControls[2] as? NSButton)?.state = dimWhenInactive ? .on : .off
        (preferenceControls[3] as? NSButton)?.state = hideSidebar ? .on : .off
        (preferenceControls[4] as? NSPopUpButton)?.selectItem(
            withTag: Int((defaults.double(forKey: "inactiveOpacity") * 100).rounded()))
    }

    @objc private func preferenceChanged(_ sender: NSControl) {
        switch sender.tag {
        case 1: floatOnTop = (sender as! NSButton).state == .on
        case 2: dimWhenInactive = (sender as! NSButton).state == .on
        case 3: hideSidebar = (sender as! NSButton).state == .on
        case 4:
            defaults.set(Double((sender as! NSPopUpButton).selectedTag()) / 100, forKey: "inactiveOpacity")
            dimWhenInactive = true
        default: break
        }
        refreshPreferenceControls()
    }

    @objc private func resetPreferences() {
        useNormalBehavior()
        refreshPreferenceControls()
    }

    private func applyWindowBehavior() {
        guard let window = window else { return }
        window.level = floatOnTop ? .floating : .normal
        let opacity = WindowBehavior.opacity(isActive: window.isKeyWindow || !popups.isEmpty,
                                             dimWhenInactive: dimWhenInactive,
                                             inactiveOpacity: defaults.double(forKey: "inactiveOpacity"))
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            window.animator().alphaValue = opacity
        }
    }

    private func updateSidebar() {
        // Update future navigations as well as the current SPA document.
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        for resource in ["Cost", "CostDisplay"] {
            if let url = Bundle.main.url(forResource: resource, withExtension: "js"),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentEnd,
                                                     forMainFrameOnly: true, in: .defaultClient))
            }
        }
        if let url = Bundle.main.url(forResource: "Sidebar", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            let script = "window.__activeTaskSidebarEnabled = \(hideSidebar ? "true" : "false");\n" + source
            controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd,
                                                forMainFrameOnly: true, in: .defaultClient))
        }
        let script = "window.__activeTaskSidebar?.setEnabled(\(hideSidebar ? "true" : "false"));"
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient, completionHandler: nil)
    }

    @objc func showWindow(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        applyWindowBehavior()
    }
    @objc private func goHome() { showWindow(nil); webView.load(URLRequest(url: homeURL)) }
    @objc private func goOrganization() {
        showWindow(nil)
        webView.load(URLRequest(url: URL(string: "https://www.perplexity.ai/account/org/credits-usage")!))
    }
    @objc private func reload() { webView.reload() }
    @objc private func openInBrowser() { NSWorkspace.shared.open(webView.url ?? homeURL) }
    @objc private func zoomIn() { setZoom(webView.pageZoom + 0.1) }
    @objc private func zoomOut() { setZoom(webView.pageZoom - 0.1) }
    @objc private func zoomReset() { setZoom(1) }
    private func setZoom(_ value: Double) {
        webView.pageZoom = min(1.8, max(0.6, value))
        defaults.set(webView.pageZoom, forKey: "zoom")
    }
    @objc private func about() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Active Task",
            .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            .credits: NSAttributedString(string: "A tiny, independent window for Perplexity Computer.\nOpen source. MIT licensed. Not affiliated with Perplexity.")
        ])
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(nil); return true
    }
    func windowDidBecomeKey(_ notification: Notification) { applyWindowBehavior() }
    func windowDidResignKey(_ notification: Notification) { applyWindowBehavior() }
    func windowWillClose(_ notification: Notification) {
        guard let closed = notification.object as? NSWindow, closed !== window else { return }
        popups.removeAll { $0 === closed }
        applyWindowBehavior()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView === self.webView else { return }
        errorLabel.isHidden = true
        progress?.startAnimation(nil)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === self.webView else { return }
        progress?.stopAnimation(nil)
        updateSidebar()
        #if SCREENSHOT_BUILD
        if screenshotDirectory != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.captureDocumentationScreenshots() }
        }
        #endif
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error, in: webView)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error, in: webView)
    }
    private func showError(_ error: Error, in source: WKWebView) {
        guard source === webView else { return }
        progress?.stopAnimation(nil)
        if (error as NSError).code == NSURLErrorCancelled { return }
        errorLabel.stringValue = "Could not load Perplexity.\n\(error.localizedDescription)\n\nCheck your connection and press ⌘R to retry."
        errorLabel.isHidden = false
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { webView.reload() }

    // Only Perplexity and common identity providers stay inside the app.
    private func isInternal(_ url: URL) -> Bool {
        #if SCREENSHOT_BUILD
        if screenshotDirectory != nil && url.isFileURL { return true }
        #endif
        guard let host = url.host?.lowercased() else { return url.absoluteString == "about:blank" }
        let domains = ["perplexity.ai", "accounts.google.com", "appleid.apple.com",
                       "appleid.apple.com.cn", "accounts.apple.com", "challenges.cloudflare.com"]
        return url.scheme == "https" && domains.contains { host == $0 || host.hasSuffix("." + $0) }
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        if action.shouldPerformDownload { decisionHandler(.download); return }
        if action.targetFrame?.isMainFrame == false { decisionHandler(.allow); return }
        if isInternal(url) { decisionHandler(.allow); return }
        if ["https", "http", "mailto"].contains(url.scheme ?? "") {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(response.canShowMIMEType ? .allow : .download)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.targetFrame == nil else { return nil }
        if let url = action.request.url, !isInternal(url) {
            if ["https", "http", "mailto"].contains(url.scheme ?? "") { NSWorkspace.shared.open(url) }
            return nil
        }
        let popup = WKWebView(frame: .zero, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        let popupWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
                                   styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        popupWindow.title = "Sign in to Perplexity"
        popupWindow.contentView = popup
        popupWindow.isReleasedWhenClosed = false
        popupWindow.delegate = self
        popupWindow.level = window.level
        popupWindow.center()
        popups.append(popupWindow)
        popupWindow.makeKeyAndOrderFront(nil)
        applyWindowBehavior()
        return popup
    }
    func webViewDidClose(_ webView: WKWebView) {
        popups.first { $0.contentView === webView }?.close()
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.beginSheetModal(for: webView.window ?? window) { _ in completionHandler() }
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: webView.window ?? window) { completionHandler($0 == .alertFirstButtonReturn) }
    }
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = (suggestedFilename as NSString).lastPathComponent
        panel.beginSheetModal(for: window) { result in
            completionHandler(result == .OK ? panel.url : nil)
        }
    }

    #if SCREENSHOT_BUILD
    // Native UI + actual WKWebView snapshot, composed without screen-recording
    // permissions. Only available in a separately compiled documentation build.
    private func saveWindowSnapshot(_ target: NSWindow, webImage: NSImage? = nil, name: String) throws {
        guard let directory = screenshotDirectory,
              let frameView = target.contentView?.superview,
              let bitmap = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else {
            fatalError("Cannot snapshot native window")
        }
        target.displayIfNeeded()
        frameView.cacheDisplay(in: frameView.bounds, to: bitmap)
        let image = NSImage(size: frameView.bounds.size)
        image.lockFocus()
        bitmap.draw(in: frameView.bounds)
        if let webImage = webImage {
            let rect = webView.convert(webView.bounds, to: frameView)
            webImage.draw(in: rect)
        }
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let output = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            fatalError("Cannot encode screenshot")
        }
        try output.write(to: directory.appendingPathComponent(name))
    }

    private func captureDocumentationScreenshots() {
        guard let directory = screenshotDirectory else { return }
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        catch { fatalError("Cannot create screenshots directory: \(error)") }
        webView.takeSnapshot(with: nil) { image, error in
            guard let image = image else { fatalError("WebKit snapshot failed: \(String(describing: error))") }
            do {
                try self.saveWindowSnapshot(self.window, webImage: image, name: "screenshot-overview.png")
                self.captureCostScene("session", path: "/computer/tasks/documentation", name: "screenshot-session-cost.png") {
                    self.captureCostScene("organization", path: "/account/org/credits-usage", name: "screenshot-organization-cost.png") {
                        self.dimWhenInactive = true
                        self.showPreferences()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            do {
                                try self.saveWindowSnapshot(self.preferencesWindow!, name: "screenshot-settings.png")
                                print("Documentation screenshots saved to \(directory.path)")
                                NSApp.terminate(nil)
                            } catch { fatalError("Settings screenshot failed: \(error)") }
                        }
                    }
                }
            } catch { fatalError("Overview screenshot failed: \(error)") }
        }
    }
    private func captureCostScene(_ scene: String, path: String, name: String, completion: @escaping () -> Void) {
        webView.evaluateJavaScript("window.showScene('\(scene)')") { _, error in
            if let error = error { fatalError("Scene failed: \(error)") }
            let script = """
            if (!window.__atDocLocation) {
              window.__atDocLocation = { hostname: 'www.perplexity.ai', pathname: '\(path)' };
              window.__atDocCost = ActiveTaskCostDisplay.start({location: window.__atDocLocation});
            } else {
              window.__atDocLocation.pathname = '\(path)';
            }
            window.__atDocCost.refresh();
            """
            self.webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
                if case .failure(let error) = result { fatalError("Cost fixture injection failed: \(error)") }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.webView.takeSnapshot(with: nil) { image, error in
                        guard let image = image else { fatalError("Cost snapshot failed: \(String(describing: error))") }
                        do {
                            try self.saveWindowSnapshot(self.window, webImage: image, name: name)
                            completion()
                        } catch { fatalError("Cost screenshot failed: \(error)") }
                    }
                }
            }
        }
    }
    #endif
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
