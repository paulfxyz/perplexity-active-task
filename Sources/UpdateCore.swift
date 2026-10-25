import Foundation
import CryptoKit
import CoreFoundation

struct UpdateFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

struct AppVersion: Comparable, Equatable {
    let components: [Int]
    init?(_ string: String) {
        let value = string.hasPrefix("v") ? String(string.dropFirst()) : string
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }),
                  (part.count == 1 || part.first != "0"), let number = Int(part) else { return nil }
            numbers.append(number)
        }
        components = numbers
    }
    var string: String { components.map(String.init).joined(separator: ".") }
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.components.lexicographicallyPrecedes(rhs.components)
    }
}

struct UpdateRelease {
    let version: String
    let downloadURL: URL
    let digest: String
    let size: Int
}

struct PreparedUpdate {
    let target: URL
    let candidate: URL
    let stage: URL
    let helper: URL
    let oldVersion: String
    let newVersion: String
}

enum UpdateCore {
    static let repository = "paulfxyz/perplexity-active-task"
    static let bundleID = "com.paulfleury.activetask"
    static let archiveName = "Active-Task-macOS-universal.zip"
    static let maximumArchiveBytes = 100 * 1024 * 1024
    static let feedURL = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    static let releasesURL = URL(string: "https://github.com/\(repository)/releases")!

    static func trustedURL(_ url: URL) -> Bool {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "https", parts.user == nil, parts.password == nil,
              parts.port == nil, parts.fragment == nil, let host = parts.host else { return false }
        return ["api.github.com", "github.com", "release-assets.githubusercontent.com",
                "objects.githubusercontent.com"].contains(host)
    }

    static func release(from data: Data, currentVersion: String) throws -> UpdateRelease? {
        guard data.count <= 2 * 1024 * 1024,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let draft = object["draft"] as? Bool, !draft,
              let prerelease = object["prerelease"] as? Bool, !prerelease,
              let tag = object["tag_name"] as? String,
              let version = AppVersion(tag), tag == "v\(version.string)",
              let current = AppVersion(currentVersion) else {
            throw UpdateFailure("GitHub returned unsupported release metadata.")
        }
        guard version > current else { return nil }
        let expected = "https://github.com/\(repository)/releases/download/\(tag)/\(archiveName)"
        guard let assets = object["assets"] as? [[String: Any]],
              let asset = assets.first(where: { ($0["name"] as? String) == archiveName }),
              asset["state"] as? String == "uploaded",
              let address = asset["browser_download_url"] as? String, address == expected,
              let url = URL(string: address), trustedURL(url),
              let sizeNumber = asset["size"] as? NSNumber,
              CFGetTypeID(sizeNumber) != CFBooleanGetTypeID(),
              sizeNumber.doubleValue.rounded() == sizeNumber.doubleValue,
              sizeNumber.doubleValue > 0, sizeNumber.doubleValue <= Double(maximumArchiveBytes),
              let digest = asset["digest"] as? String,
              digest.range(of: "^sha256:[a-f0-9]{64}$", options: .regularExpression) != nil else {
            throw UpdateFailure("The release has no supported ZIP with a GitHub SHA-256 digest. Use GitHub Releases or try again later.")
        }
        return UpdateRelease(version: version.string, downloadURL: url,
                             digest: String(digest.dropFirst(7)), size: sizeNumber.intValue)
    }

    static func verifyArchive(_ archive: URL, release: UpdateRelease) throws {
        let size = try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard size == release.size, release.size > 0, release.size <= maximumArchiveBytes else {
            throw UpdateFailure("Update size does not match the release; installation stopped.")
        }
        let data = try Data(contentsOf: archive, options: .mappedIfSafe)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == release.digest else {
            throw UpdateFailure("Update checksum mismatch; installation stopped.")
        }
    }

    @discardableResult
    static func run(_ executable: String, _ arguments: [String], timeout: Double = 60) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let timeoutAction = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutAction)
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        timeoutAction.cancel()
        let text = String(decoding: data, as: UTF8.self)
        guard process.terminationStatus == 0 else {
            throw UpdateFailure("Update validation failed (\((executable as NSString).lastPathComponent)): \(text.prefix(600))")
        }
        return text
    }

    static func validateEntryNames(_ names: [String]) throws {
        guard !names.isEmpty, names.count < 10_000 else { throw UpdateFailure("Unsupported update archive layout.") }
        for name in names {
            let components = name.split(separator: "/", omittingEmptySubsequences: false)
            guard !name.isEmpty, !name.hasPrefix("/"), !name.contains("\\"),
                  !components.contains(".."), !components.contains("."),
                  !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
                  name == "Active Task.app/" || name.hasPrefix("Active Task.app/") ||
                  name == "__MACOSX/" || name.hasPrefix("__MACOSX/") else {
                throw UpdateFailure("Unsafe path in update archive; installation stopped.")
            }
        }
    }

    static func readVersion(_ app: URL) throws -> String {
        let data = try Data(contentsOf: app.appendingPathComponent("Contents/Info.plist"))
        guard let info = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              info["CFBundleIdentifier"] as? String == bundleID,
              info["CFBundlePackageType"] as? String == "APPL",
              info["CFBundleExecutable"] as? String == "ActiveTask",
              let version = info["CFBundleShortVersionString"] as? String,
              AppVersion(version) != nil else {
            throw UpdateFailure("Unexpected application identity or version.")
        }
        return version
    }

    static func universalArchitectures(_ data: Data) -> Bool {
        func word(_ offset: Int) -> UInt32? {
            guard offset >= 0, offset + 4 <= data.count else { return nil }
            return data[offset..<(offset + 4)].reduce(0) { ($0 << 8) | UInt32($1) }
        }
        guard word(0) == 0xcafebabe, let count = word(4), count > 0, count <= 8,
              data.count >= 8 + Int(count) * 20 else { return false }
        let cpus = Set((0..<Int(count)).compactMap { word(8 + $0 * 20) })
        return cpus.contains(0x0100000c) && cpus.contains(0x01000007)
    }

    static func validateBundle(_ app: URL, version: String) throws {
        let manager = FileManager.default
        guard try app.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true,
              try readVersion(app) == version else {
            throw UpdateFailure("Unexpected update version or bundle path.")
        }
        guard let enumerator = manager.enumerator(at: app, includingPropertiesForKeys: [.isSymbolicLinkKey]) else {
            throw UpdateFailure("Cannot inspect update bundle.")
        }
        for case let file as URL in enumerator {
            if try file.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true {
                throw UpdateFailure("Symbolic links are not allowed in this app's update bundle.")
            }
        }
        let binary = app.appendingPathComponent("Contents/MacOS/ActiveTask")
        guard manager.isExecutableFile(atPath: binary.path),
              universalArchitectures(try Data(contentsOf: binary, options: .mappedIfSafe)) else {
            throw UpdateFailure("The update is not a supported Apple silicon and Intel executable.")
        }
        try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
    }

    static func prepare(archive: URL, version: String, target: URL, helperSource: URL) throws -> PreparedUpdate {
        let manager = FileManager.default
        let target = target.standardizedFileURL
        guard target.lastPathComponent == "Active Task.app",
              !target.pathComponents.contains("AppTranslocation"),
              !target.path.hasPrefix("/Volumes/"),
              try target.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw UpdateFailure("Move Active Task.app to a writable Applications folder before updating.")
        }
        let oldVersion = try readVersion(target)
        guard let next = AppVersion(version), let old = AppVersion(oldVersion), next > old else {
            throw UpdateFailure("Refusing an older or already installed update.")
        }
        let parent = target.deletingLastPathComponent()
        guard manager.isWritableFile(atPath: parent.path) else {
            throw UpdateFailure("The app's folder is not writable. Use a writable Applications folder or install manually; administrator access is never requested.")
        }
        let listing = try run("/usr/bin/zipinfo", ["-1", archive.path])
        guard listing.utf8.count < 2 * 1024 * 1024 else { throw UpdateFailure("Update archive has too many entries.") }
        try validateEntryNames(listing.split(separator: "\n").map(String.init))
        let attributes = try run("/usr/bin/zipinfo", ["-l", archive.path])
        guard !attributes.split(separator: "\n").contains(where: { $0.hasPrefix("l") }) else {
            throw UpdateFailure("Symbolic links in the archive are not supported.")
        }
        let stage = parent.appendingPathComponent(".active-task-update-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: stage, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        do {
            try run("/usr/bin/ditto", ["-x", "-k", archive.path, stage.path])
            let candidate = stage.appendingPathComponent("Active Task.app", isDirectory: true)
            try validateBundle(candidate, version: version)
            let helper = stage.appendingPathComponent("install-update.sh")
            try manager.copyItem(at: helperSource, to: helper)
            try manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: helper.path)
            return PreparedUpdate(target: target, candidate: candidate, stage: stage, helper: helper,
                                  oldVersion: oldVersion, newVersion: version)
        } catch {
            try? manager.removeItem(at: stage)
            throw error
        }
    }
}
