import Foundation

enum WindowBehavior {
    static let inactiveOpacityPercentages = [5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95]

    static func normalizedInactiveOpacity(_ value: Double) -> Double {
        guard value.isFinite else { return 0.6 }
        let percent = value * 100
        let nearest = inactiveOpacityPercentages.min {
            abs(Double($0) - percent) < abs(Double($1) - percent) - 0.000001
        }!
        return Double(nearest) / 100
    }

    static func opacity(isActive: Bool, dimWhenInactive: Bool, inactiveOpacity: Double) -> Double {
        guard !isActive && dimWhenInactive else { return 1 }
        let value = inactiveOpacity.isFinite ? inactiveOpacity : 0.6
        return min(0.95, max(0.05, value))
    }
}
