import AppKit

@MainActor
final class UpdateController {
    private let defaults: UserDefaults
    private let currentVersion: String
    private var timer: Timer?
    private var busy = false
    private(set) var statusText = "Updates have not been checked."
    var onStatusChange: ((String) -> Void)?

    init(defaults: UserDefaults, currentVersion: String) {
        self.defaults = defaults
        self.currentVersion = currentVersion
        defaults.register(defaults: ["automaticUpdateChecks": true])
    }

    private func status(_ text: String) {
        statusText = text
        onStatusChange?(text)
    }

    func start() {
        timer?.invalidate()
        guard defaults.bool(forKey: "automaticUpdateChecks") else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check(manual: false) }
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard let self = self, self.defaults.bool(forKey: "automaticUpdateChecks") else { return }
            self.check(manual: false)
        }
    }

    func setAutomaticChecks(_ enabled: Bool) {
        defaults.set(enabled, forKey: "automaticUpdateChecks")
        timer?.invalidate()
        timer = nil
        if enabled { start() }
    }

    func check(manual: Bool) {
        guard !busy else {
            if manual { showMessage("Update already in progress", detail: statusText) }
            return
        }
        busy = true
        status("Checking GitHub Releases…")
        Task {
            do {
                let metadata = try await UpdateHTTP.download(UpdateCore.feedURL, maxBytes: 2 * 1024 * 1024)
                defer { try? FileManager.default.removeItem(at: metadata) }
                let release = try UpdateCore.release(from: Data(contentsOf: metadata), currentVersion: currentVersion)
                busy = false
                defaults.set(Date(), forKey: "lastUpdateCheck")
                if let release = release {
                    status("Version \(release.version) is available.")
                    if manual { offer(release) }
                } else {
                    status("Version \(currentVersion) is up to date.")
                    if manual { showMessage("You're up to date", detail: "Active Task \(currentVersion) is the latest supported stable release.") }
                }
            } catch {
                busy = false
                status("Update check failed. Try again later.")
                if manual { showMessage("Could not check for updates", detail: error.localizedDescription, releasesButton: true) }
            }
        }
    }

    private func offer(_ release: UpdateRelease) {
        let alert = NSAlert()
        alert.messageText = "Active Task \(release.version) is available"
        alert.informativeText = """
        You are running \(currentVersion). Download & Restart will download and verify the update, quit this app, replace it, and reopen it. Your website session and preferences are left in place.

        The previous app will be retained for recovery. This community build remains ad-hoc signed, not Apple-notarized.
        """
        alert.addButton(withTitle: "Download & Restart")
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "View Releases")
        alert.window.level = .floating
        let response = alert.runModal()
        if response == .alertFirstButtonReturn { install(release) }
        else if response == .alertThirdButtonReturn { NSWorkspace.shared.open(UpdateCore.releasesURL) }
    }

    private func install(_ release: UpdateRelease) {
        guard !busy else { return }
        busy = true
        status("Downloading \(release.version)…")
        Task {
            var stage: URL?
            do {
                let archive = try await UpdateHTTP.download(
                    release.downloadURL, maxBytes: UpdateCore.maximumArchiveBytes, expectedBytes: release.size
                ) { [weak self] fraction in
                    Task { @MainActor in self?.status("Downloading… \(Int(fraction * 100))%") }
                }
                defer { try? FileManager.default.removeItem(at: archive) }
                status("Verifying update and preparing restart…")
                guard let helperSource = Bundle.main.url(forResource: "InstallUpdate", withExtension: "sh") else {
                    throw UpdateFailure("The update helper is missing. Download this release manually.")
                }
                let target = Bundle.main.bundleURL
                let prepared = try await Task.detached(priority: .userInitiated) {
                    try UpdateCore.verifyArchive(archive, release: release)
                    return try UpdateCore.prepare(archive: archive, version: release.version,
                                                  target: target, helperSource: helperSource)
                }.value
                stage = prepared.stage
                try? FileManager.default.removeItem(at: archive)
                try launchInstaller(prepared)
                status("Restarting to install \(release.version)…")
                NSApp.terminate(nil)
            } catch {
                if let stage = stage { try? FileManager.default.removeItem(at: stage) }
                busy = false
                status("Update not installed.")
                showMessage("Could not install the update", detail: error.localizedDescription, releasesButton: true)
            }
        }
    }

    private func launchInstaller(_ prepared: PreparedUpdate) throws {
        let logURL = prepared.stage.appendingPathComponent("update.log")
        guard FileManager.default.createFile(atPath: logURL.path, contents: nil,
                                             attributes: [.posixPermissions: 0o600]) else {
            throw UpdateFailure("Cannot create a private update log.")
        }
        let log = try FileHandle(forWritingTo: logURL)
        defer { try? log.close() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [prepared.helper.path, String(ProcessInfo.processInfo.processIdentifier),
                             prepared.target.path, prepared.candidate.path, prepared.stage.path,
                             prepared.oldVersion, prepared.newVersion, "active-task-update-v1"]
        process.currentDirectoryURL = prepared.stage
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        try process.run()
    }

    private func showMessage(_ title: String, detail: String, releasesButton: Bool = false) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        if releasesButton { alert.addButton(withTitle: "Open GitHub Releases") }
        alert.window.level = .floating
        if alert.runModal() == .alertSecondButtonReturn { NSWorkspace.shared.open(UpdateCore.releasesURL) }
    }
}
