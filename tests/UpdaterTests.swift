import Foundation
import CryptoKit

@main
struct UpdaterTests {
    static var checks = 0
    static func check(_ value: @autoclosure () throws -> Bool, _ label: String) throws {
        checks += 1
        guard try value() else { throw UpdateFailure("TEST FAILED: \(label)") }
    }
    static func rejects(_ label: String, containing expected: String? = nil, _ body: () throws -> Void) throws {
        do { try body() } catch {
            if let expected = expected, !error.localizedDescription.contains(expected) {
                throw UpdateFailure("TEST FAILED: \(label) rejected for the wrong reason: \(error)")
            }
            checks += 1
            return
        }
        throw UpdateFailure("TEST FAILED: accepted \(label)")
    }
    static func metadata(tag: String = "v2.0.0", digest: String = "sha256:" + String(repeating: "a", count: 64),
                         size: Any = 100, address: String? = nil) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "draft": false, "prerelease": false, "tag_name": tag,
            "assets": [["name": UpdateCore.archiveName, "state": "uploaded", "size": size,
                        "digest": digest, "browser_download_url":
                          address ?? "https://github.com/\(UpdateCore.repository)/releases/download/\(tag)/\(UpdateCore.archiveName)"]]
        ])
    }

    static func main() async throws {
        if CommandLine.arguments.contains("--live") {
            try await liveProbe()
            return
        }
        try check(AppVersion("2.0.0")! > AppVersion("1.99.99")!, "major comparison")
        try check(AppVersion("2.10.0")! > AppVersion("2.9.99")!, "numeric comparison")
        try check(AppVersion("v2.0.0") == AppVersion("2.0.0"), "tag prefix")
        for invalid in ["2", "2.0", "02.0.0", "2.0.-1", "2.0.0-beta", "2.0.0.1", "", "∞.0.0"] {
            try check(AppVersion(invalid) == nil, "reject invalid version")
        }
        for address in ["https://api.github.com/x", "https://github.com/x",
                        "https://release-assets.githubusercontent.com/x?sig=abc",
                        "https://objects.githubusercontent.com/x"] {
            try check(UpdateCore.trustedURL(URL(string: address)!), "trusted host")
        }
        for address in ["http://github.com/x", "https://github.com.evil.test/x",
                        "https://evil.test/github.com", "https://user:pw@github.com/x",
                        "https://github.com:444/x", "https://github.com/x#fragment"] {
            try check(!UpdateCore.trustedURL(URL(string: address)!), "reject redirect host")
        }
        let valid = try metadata()
        try check(try UpdateCore.release(from: valid, currentVersion: "1.1.0")?.version == "2.0.0", "available release")
        try check(try UpdateCore.release(from: valid, currentVersion: "2.0.0")?.version == nil, "already current")
        try check(try UpdateCore.release(from: valid, currentVersion: "3.0.0")?.version == nil, "never downgrade")
        try rejects("missing digest") { _ = try UpdateCore.release(from: metadata(digest: ""), currentVersion: "1.1.0") }
        try rejects("wrong download repository") {
            _ = try UpdateCore.release(from: metadata(address: "https://github.com/other/project/file.zip"), currentVersion: "1.1.0")
        }
        for size in [0, -1, true, 1.5, 100 * 1024 * 1024 + 1] as [Any] {
            try rejects("bad asset size") { _ = try UpdateCore.release(from: metadata(size: size), currentVersion: "1.1.0") }
        }
        try rejects("prerelease") {
            var value = try JSONSerialization.jsonObject(with: valid) as! [String: Any]
            value["prerelease"] = true
            _ = try UpdateCore.release(from: JSONSerialization.data(withJSONObject: value), currentVersion: "1.1.0")
        }
        try rejects("draft") {
            var value = try JSONSerialization.jsonObject(with: valid) as! [String: Any]
            value["draft"] = true
            _ = try UpdateCore.release(from: JSONSerialization.data(withJSONObject: value), currentVersion: "1.1.0")
        }
        for tag in ["2.0.0", "v2.0.0-beta", "v02.0.0"] {
            try rejects("unsupported release tag") {
                _ = try UpdateCore.release(from: metadata(tag: tag), currentVersion: "1.1.0")
            }
        }
        try UpdateCore.validateEntryNames(["Active Task.app/", "Active Task.app/Contents/Info.plist", "__MACOSX/._Active Task.app"])
        checks += 1
        for entry in ["/tmp/escape", "../escape", "Active Task.app/../escape", "Other.app/Contents/a",
                      "Active Task.app/a\\b", "Active Task.app/a\nb", "./Active Task.app/a"] {
            try rejects("unsafe archive path") { try UpdateCore.validateEntryNames([entry]) }
        }
        try check(!UpdateCore.universalArchitectures(Data("not a Mach-O".utf8)), "bad executable")
        let macOS = OperatingSystemVersion(majorVersion: 15, minorVersion: 1, patchVersion: 0)
        try check(UpdateCore.supportsMinimumOS("13.0", current: macOS), "older supported OS")
        try check(UpdateCore.supportsMinimumOS("15.1.0", current: macOS), "same supported OS")
        try check(!UpdateCore.supportsMinimumOS("15.1.1", current: macOS), "newer OS refused")
        try check(!UpdateCore.supportsMinimumOS("99.0", current: macOS), "future OS refused")
        try check(!UpdateCore.supportsMinimumOS("invalid", current: macOS), "invalid OS refused")
        try nativeInstallerIntegration()
        print("\(checks) updater checks passed, including real native replacement/reopen and injected launch-failure rollback.")
    }

    static func writeFixture(_ app: URL, version: String, marker: URL, sourceDirectory: URL) throws {
        let manager = FileManager.default
        let binary = app.appendingPathComponent("Contents/MacOS/ActiveTask")
        try manager.createDirectory(at: binary.deletingLastPathComponent(), withIntermediateDirectories: true)
        let source = sourceDirectory.appendingPathComponent("fixture.c")
        let c = """
        #include <stdio.h>
        int main(void) { FILE *f=fopen(\(String(reflecting: marker.path)), "w"); if(!f)return 1; fputs("ok",f); fclose(f); return 0; }
        """
        try c.write(to: source, atomically: true, encoding: .utf8)
        try UpdateCore.run("/usr/bin/clang", ["-arch", "arm64", "-arch", "x86_64", source.path, "-o", binary.path])
        let plist: [String: Any] = [
            "CFBundleIdentifier": UpdateCore.bundleID, "CFBundleName": "Active Task",
            "CFBundleExecutable": "ActiveTask", "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": version, "CFBundleVersion": version,
            "LSMinimumSystemVersion": "13.0"
        ]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: app.appendingPathComponent("Contents/Info.plist"))
        try UpdateCore.run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", app.path])
    }

    static func nativeInstallerIntegration() throws {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent("active-task-update-tests-\(UUID().uuidString)")
        try manager.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: root) }
        let installed = root.appendingPathComponent("installed/Active Task.app")
        let candidate = root.appendingPathComponent("candidate/Active Task.app")
        let marker = root.appendingPathComponent("launched")
        try writeFixture(installed, version: "1.1.0", marker: marker, sourceDirectory: root)
        try writeFixture(candidate, version: "2.0.0", marker: marker, sourceDirectory: root)
        let archive = root.appendingPathComponent("release.zip")
        try UpdateCore.run("/usr/bin/ditto", ["-c", "-k", "--keepParent", candidate.path, archive.path])
        let data = try Data(contentsOf: archive)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let release = UpdateRelease(version: "2.0.0", downloadURL: UpdateCore.feedURL, digest: digest, size: data.count)
        try UpdateCore.verifyArchive(archive, release: release)
        checks += 1
        try rejects("wrong checksum") {
            try UpdateCore.verifyArchive(archive, release: UpdateRelease(version: "2.0.0", downloadURL: UpdateCore.feedURL,
                                                                         digest: String(repeating: "0", count: 64), size: data.count))
        }
        try rejects("wrong size") {
            try UpdateCore.verifyArchive(archive, release: UpdateRelease(version: "2.0.0", downloadURL: UpdateCore.feedURL,
                                                                         digest: digest, size: data.count + 1))
        }
        try rejects("wrong bundle version") { try UpdateCore.validateBundle(candidate, version: "9.9.9") }
        let helper = URL(fileURLWithPath: manager.currentDirectoryPath).appendingPathComponent("scripts/install-update.sh")
        let prepared = try UpdateCore.prepare(archive: archive, version: "2.0.0", target: installed, helperSource: helper)
        try UpdateCore.run("/bin/bash", [prepared.helper.path, "999999", installed.path, prepared.candidate.path,
                                        prepared.stage.path, prepared.oldVersion, prepared.newVersion, "active-task-update-v1"])
        for _ in 0..<40 {
            if manager.fileExists(atPath: marker.path) { break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        try check(try String(contentsOf: marker, encoding: .utf8) == "ok", "new app reopened")
        try check(try UpdateCore.readVersion(installed) == "2.0.0", "new version installed")
        try check(manager.fileExists(atPath: prepared.stage.appendingPathComponent("Previous Active Task.app").path), "backup retained")
        try UpdateCore.validateBundle(installed, version: "2.0.0")
        checks += 1
        try rejects("reinstall or downgrade") {
            _ = try UpdateCore.prepare(archive: archive, version: "2.0.0", target: installed, helperSource: helper)
        }
        // A disposable helper copy replaces only the launch command to exercise
        // the real rollback branch. No runtime test bypass ships in the app.
        try manager.removeItem(at: candidate)
        try writeFixture(candidate, version: "2.0.1", marker: marker, sourceDirectory: root)
        try manager.removeItem(at: archive)
        try UpdateCore.run("/usr/bin/ditto", ["-c", "-k", "--keepParent", candidate.path, archive.path])
        let rollback = try UpdateCore.prepare(archive: archive, version: "2.0.1", target: installed, helperSource: helper)
        let source = try String(contentsOf: rollback.helper, encoding: .utf8)
        try check(source.contains("/usr/bin/open -n \"$TARGET\""), "fault injection matches one launch statement")
        try source.replacingOccurrences(of: "/usr/bin/open -n \"$TARGET\"", with: "/usr/bin/false")
            .write(to: rollback.helper, atomically: true, encoding: .utf8)
        try rejects("launch failure") {
            try UpdateCore.run("/bin/bash", [rollback.helper.path, "999999", installed.path, rollback.candidate.path,
                                            rollback.stage.path, rollback.oldVersion, rollback.newVersion, "active-task-update-v1"])
        }
        try check(try UpdateCore.readVersion(installed) == "2.0.0", "old app restored after launch failure")
        try check(manager.fileExists(atPath: rollback.stage.appendingPathComponent("Failed Active Task.app").path), "failed app retained")
        try check(!manager.fileExists(atPath: installed.deletingLastPathComponent().appendingPathComponent(".active-task-update-lock").path), "lock released")
        let stale = try UpdateCore.prepare(archive: archive, version: "2.0.1", target: installed, helperSource: helper)
        try rejects("target changed before helper preflight", containing: "Update failed; restoring the previous app.") {
            try UpdateCore.run("/bin/bash", [stale.helper.path, "999999", installed.path, stale.candidate.path,
                                            stale.stage.path, "1.1.0", stale.newVersion, "active-task-update-v1"])
        }
        try check(try UpdateCore.readVersion(installed) == "2.0.0", "late preflight leaves installed version intact")
        try check(!manager.fileExists(atPath: stale.stage.appendingPathComponent("Previous Active Task.app").path),
                  "late preflight does not move installed app")
        let resource = candidate.appendingPathComponent("Contents/Resources")
        try manager.createDirectory(at: resource, withIntermediateDirectories: true)
        try manager.createSymbolicLink(at: resource.appendingPathComponent("unsafe-link"), withDestinationURL: marker)
        let symlinkArchive = root.appendingPathComponent("symlink.zip")
        try UpdateCore.run("/usr/bin/ditto", ["-c", "-k", "--keepParent", candidate.path, symlinkArchive.path])
        try rejects("actual ZIP symlink", containing: "Symbolic links in the archive") {
            _ = try UpdateCore.prepare(archive: symlinkArchive, version: "2.0.1", target: installed, helperSource: helper)
        }
        try check(try UpdateCore.readVersion(installed) == "2.0.0", "symlink archive leaves target intact")
    }

    static func liveProbe() async throws {
        let metadata = try await UpdateHTTP.download(UpdateCore.feedURL, maxBytes: 2 * 1024 * 1024)
        defer { try? FileManager.default.removeItem(at: metadata) }
        guard let release = try UpdateCore.release(from: Data(contentsOf: metadata), currentVersion: "0.0.0") else {
            throw UpdateFailure("No live stable release available for the probe.")
        }
        let archive = try await UpdateHTTP.download(release.downloadURL, maxBytes: UpdateCore.maximumArchiveBytes,
                                                    expectedBytes: release.size)
        defer { try? FileManager.default.removeItem(at: archive) }
        try UpdateCore.verifyArchive(archive, release: release)
        print("Live native updater probe passed: GitHub stable feed, trusted redirects, ZIP size and SHA-256 for \(release.version). Nothing installed.")
    }
}
