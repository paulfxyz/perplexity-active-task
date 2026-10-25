import Foundation

// A separate ephemeral, cookieless client. Every redirect is checked.
final class UpdateHTTP: NSObject, URLSessionDownloadDelegate {
    private var session: URLSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private let maxBytes: Int64
    private let expectedBytes: Int64?
    private let progress: ((Double) -> Void)?
    private var redirects = 0
    private var rejection: Error?

    private init(maxBytes: Int, expectedBytes: Int?, progress: ((Double) -> Void)?) {
        self.maxBytes = Int64(maxBytes)
        self.expectedBytes = expectedBytes.map(Int64.init)
        self.progress = progress
    }

    static func download(_ url: URL, maxBytes: Int, expectedBytes: Int? = nil,
                         progress: ((Double) -> Void)? = nil) async throws -> URL {
        guard UpdateCore.trustedURL(url) else { throw UpdateFailure("Refusing an untrusted update URL.") }
        let client = UpdateHTTP(maxBytes: maxBytes, expectedBytes: expectedBytes, progress: progress)
        return try await withCheckedThrowingContinuation { continuation in
            client.continuation = continuation
            let config = URLSessionConfiguration.ephemeral
            config.httpCookieStorage = nil
            config.httpShouldSetCookies = false
            config.urlCredentialStorage = nil
            config.urlCache = nil
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 180
            let session = URLSession(configuration: config, delegate: client, delegateQueue: nil)
            client.session = session
            var request = URLRequest(url: url)
            request.setValue("Active-Task-Updater", forHTTPHeaderField: "User-Agent")
            request.setValue(url.host == "api.github.com" ? "application/vnd.github+json" : "application/octet-stream",
                             forHTTPHeaderField: "Accept")
            session.downloadTask(with: request).resume()
        }
    }

    private func finish(_ result: Result<URL, Error>) {
        guard let pending = continuation else { return }
        continuation = nil
        pending.resume(with: result)
        session?.finishTasksAndInvalidate()
        session = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        redirects += 1
        guard redirects <= 5, let url = request.url, UpdateCore.trustedURL(url) else {
            rejection = UpdateFailure("An update redirected to an unsupported address.")
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > maxBytes ||
            (totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite > maxBytes) ||
            (expectedBytes != nil && totalBytesWritten > expectedBytes!) {
            rejection = UpdateFailure("Update exceeds its permitted size.")
            downloadTask.cancel()
        } else if let expected = expectedBytes {
            progress?(Double(totalBytesWritten) / Double(expected))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            if let rejection = rejection { throw rejection }
            guard let response = downloadTask.response as? HTTPURLResponse, response.statusCode == 200,
                  let finalURL = response.url, UpdateCore.trustedURL(finalURL) else {
                let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
                throw UpdateFailure("GitHub update request failed (\(status)). Try later or use GitHub Releases.")
            }
            let size = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size > 0, Int64(size) <= maxBytes,
                  expectedBytes == nil || Int64(size) == expectedBytes else {
                throw UpdateFailure("Downloaded update has an unexpected size.")
            }
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("active-task-download-\(UUID().uuidString)")
            try FileManager.default.moveItem(at: location, to: destination)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            finish(.success(destination))
        } catch { finish(.failure(error)) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = rejection ?? error { finish(.failure(error)) }
    }
}
