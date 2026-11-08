import Foundation

@main
struct TaskCountStateTests {
    static func main() {
        var checks = 0
        func check(_ condition: Bool) { checks += 1; assert(condition) }
        let now = Date(timeIntervalSince1970: 1_000_000)
        for count in [0, 1, 4, 12, 99999] {
            let sample = TaskCountSample(count: count)
            check(sample.count == count)
            check(TaskCountPresentation(sample: sample, observedAt: now, now: now).title == " \(count)")
        }
        let four = TaskCountSample(count: 4)
        check(TaskCountPresentation(sample: four, observedAt: now.addingTimeInterval(-89), now: now).title == " 4")
        check(TaskCountPresentation(sample: four, observedAt: now.addingTimeInterval(-91), now: now).title == " …")
        check(TaskCountPresentation(sample: four, observedAt: now.addingTimeInterval(10), now: now).title == " …")
        check(TaskCountPresentation(sample: four, observedAt: nil, now: now).title == " …")
        check(TaskCountPresentation(sample: TaskCountSample(count: 50, lowerBound: true), observedAt: now, now: now).title == " 50+")
        check(TaskCountPresentation(sample: TaskCountSample(count: 1), observedAt: now, now: now).tooltip.contains("1 active task."))
        check(TaskCountPresentation(sample: four, observedAt: now, now: now, refreshing: true).tooltip.contains("Refreshing"))
        check(TaskCountSample(count: -1).count == nil)
        check(TaskCountSample(count: 100_000).count == nil)
        let valid: [String: Any] = ["version": 1, "status": "ready", "count": 4, "lowerBound": false]
        check(TaskCountSample(javaScript: valid).count == 4)
        for value in [true, -1, 4.5, Double.nan, Double.infinity, "4", 100_000] as [Any] {
            var object = valid
            object["count"] = value
            check(TaskCountSample(javaScript: object).count == nil)
        }
        var invalid = valid
        invalid["version"] = true
        check(TaskCountSample(javaScript: invalid).count == nil)
        invalid = valid
        invalid["lowerBound"] = 0
        check(TaskCountSample(javaScript: invalid).count == nil)
        invalid = valid
        invalid["status"] = "unknown"
        invalid["reason"] = "loading"
        check(TaskCountSample(javaScript: invalid).count == nil)
        check(TaskCountSample(javaScript: "not a count").count == nil)
        check(TaskCountPresentation(sample: TaskCountSample(unknown: "offline"), observedAt: nil).tooltip.contains("connection"))
        print("\(checks) native task-count validation/presentation checks passed.")
    }
}
