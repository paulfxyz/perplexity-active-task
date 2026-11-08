import AppKit
import WebKit

@MainActor
final class TaskCounter: NSObject, WKNavigationDelegate {
    private let monitor: WKWebView
    private let onUpdate: (TaskCountPresentation) -> Void
    private let home = URL(string: "https://www.perplexity.ai/computer/tasks?status=active")!
    private var timer: Timer?
    private var reading = false
    private var failed = false
    private var revision = 0
    private var lastLoad = Date.distantPast
    private var lastGood: (TaskCountSample, Date)?
    private var backgroundReady = false
    #if SCREENSHOT_BUILD
    private var fixtureURL: URL?
    private var fixtureReady: (() -> Void)?
    #endif

    init(primary: WKWebView, onUpdate: @escaping (TaskCountPresentation) -> Void) {
        self.onUpdate = onUpdate
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = primary.configuration.websiteDataStore
        configuration.processPool = primary.configuration.processPool
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        if let url = Bundle.main.url(forResource: "TaskCount", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            configuration.userContentController.addUserScript(WKUserScript(
                source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient))
        }
        monitor = WKWebView(frame: NSRect(x: 0, y: 0, width: 1100, height: 800), configuration: configuration)
        super.init()
        monitor.navigationDelegate = self
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        refresh()
    }

    func refresh() {
        guard !monitor.isLoading else { return }
        lastLoad = Date()
        #if SCREENSHOT_BUILD
        if let fixtureURL = fixtureURL {
            monitor.loadFileURL(fixtureURL, allowingReadAccessTo: fixtureURL.deletingLastPathComponent())
            return
        }
        #endif
        monitor.load(URLRequest(url: home, cachePolicy: .reloadRevalidatingCacheData))
    }

    func primaryPageDidFinish() {
        if !backgroundReady || Date().timeIntervalSince(lastLoad) > 45 { refresh() }
        poll()
    }

    private func tick() {
        if Date().timeIntervalSince(lastLoad) >= 60 { refresh() }
        poll()
    }

    private var expression: String {
        #if SCREENSHOT_BUILD
        if fixtureURL != nil {
            return "window.ActiveTaskCount?.read({location:{hostname:'www.perplexity.ai',pathname:'/computer/tasks',search:'?status=active'}})"
        }
        #endif
        return "window.ActiveTaskCount?.read()"
    }

    private func read(_ view: WKWebView, expression: String, completion: @escaping (TaskCountSample) -> Void) {
        guard !view.isLoading else { completion(TaskCountSample(unknown: "loading")); return }
        view.evaluateJavaScript(expression, in: nil, in: .defaultClient) { result in
            switch result {
            case .success(let value): completion(TaskCountSample(javaScript: value))
            case .failure: completion(TaskCountSample(unknown: "loading"))
            }
        }
    }

    private func publish(_ sample: TaskCountSample) {
        if sample.count != nil {
            lastGood = (sample, Date())
            onUpdate(TaskCountPresentation(sample: sample, observedAt: Date()))
            #if SCREENSHOT_BUILD
            if fixtureURL != nil, sample.count == 4, let ready = fixtureReady {
                fixtureReady = nil
                ready()
            }
            #endif
        } else if sample.reason == "loading", let (previous, date) = lastGood {
            onUpdate(TaskCountPresentation(sample: previous, observedAt: date, refreshing: true))
        } else {
            lastGood = nil
            onUpdate(TaskCountPresentation(sample: sample, observedAt: nil))
        }
    }

    private func poll() {
        guard !reading else { return }
        if failed { publish(TaskCountSample(unknown: "offline")); return }
        reading = true
        let generation = revision
        read(monitor, expression: expression) { [weak self] sample in
            guard let self = self else { return }
            self.reading = false
            guard generation == self.revision, !self.failed else {
                if self.failed { self.publish(TaskCountSample(unknown: "offline")) }
                return
            }
            self.backgroundReady = sample.count != nil
            self.publish(sample)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        revision += 1
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        failed = false
        #if SCREENSHOT_BUILD
        if fixtureURL != nil {
            webView.evaluateJavaScript("window.showScene('counter')") { [weak self] _, _ in self?.poll() }
            return
        }
        #endif
        webView.evaluateJavaScript("window.ActiveTaskCount?.expandGroups()", in: nil, in: .defaultClient) { [weak self] _ in
            self?.poll()
        }
    }
    private func loadFailed(_ error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        failed = true
        backgroundReady = false
        publish(TaskCountSample(unknown: "offline"))
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { loadFailed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { loadFailed(error) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        backgroundReady = false
        refresh()
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        #if SCREENSHOT_BUILD
        if fixtureURL != nil && url.isFileURL { decisionHandler(.allow); return }
        #endif
        if action.targetFrame?.isMainFrame == false { decisionHandler(.allow); return }
        decisionHandler(url.scheme == "https" && ["perplexity.ai", "www.perplexity.ai"].contains(url.host ?? "") ? .allow : .cancel)
    }

    #if SCREENSHOT_BUILD
    func startDocumentationFixture(_ url: URL, completion: @escaping () -> Void) {
        fixtureURL = url
        fixtureReady = completion
        start()
    }
    #endif
}
