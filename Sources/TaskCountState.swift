import Foundation
import CoreFoundation

struct TaskCountSample {
    let count: Int?
    let lowerBound: Bool
    let reason: String

    init(count: Int, lowerBound: Bool = false) {
        self.count = (0...99_999).contains(count) ? count : nil
        self.lowerBound = lowerBound
        self.reason = self.count == nil ? "unsupported" : ""
    }
    init(unknown reason: String) {
        count = nil
        lowerBound = false
        self.reason = ["loading", "offline", "auth", "origin", "route", "filtered", "collapsed", "unsupported"].contains(reason)
            ? reason : "unsupported"
    }
    init(javaScript value: Any) {
        guard let object = value as? [String: Any], let version = object["version"] as? NSNumber,
              CFGetTypeID(version) != CFBooleanGetTypeID(), version.doubleValue == 1,
              object["status"] as? String == "ready", let number = object["count"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite,
              number.doubleValue.rounded() == number.doubleValue,
              (0...99_999).contains(number.doubleValue), let lower = object["lowerBound"] as? NSNumber,
              CFGetTypeID(lower) == CFBooleanGetTypeID() else {
            let reason = (value as? [String: Any])?["reason"] as? String ?? "unsupported"
            self.init(unknown: reason)
            return
        }
        self.init(count: number.intValue, lowerBound: lower.boolValue)
    }
}

struct TaskCountPresentation {
    let title: String
    let summary: String
    let tooltip: String

    init(sample: TaskCountSample, observedAt: Date?, now: Date = Date(), refreshing: Bool = false) {
        guard let count = sample.count, let date = observedAt, now.timeIntervalSince(date) <= 90,
              now.timeIntervalSince(date) >= -5 else {
            title = " …"
            summary = "Active tasks: unavailable"
            tooltip = sample.reason == "offline"
                ? "Active Task: unable to refresh. Check your connection."
                : "Active Task: count unavailable. Sign in and wait for the active dashboard to load."
            return
        }
        let label = "\(count)\(sample.lowerBound ? "+" : "")"
        title = " \(label)"
        summary = "Active tasks: \(label)"
        tooltip = "\(label) active \(count == 1 && !sample.lowerBound ? "task" : "tasks")"
            + (sample.lowerBound ? " (at least; the dashboard may contain more rows)." : ".")
            + (refreshing ? " Refreshing the last observed count…" : " Includes pinned and unpinned sessions.")
    }
}
