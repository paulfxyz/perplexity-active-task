import Foundation

enum WindowBehavior {
    static func opacity(isActive: Bool, dimWhenInactive: Bool, inactiveOpacity: Double) -> Double {
        guard !isActive && dimWhenInactive else { return 1 }
        return min(1, max(0.25, inactiveOpacity))
    }
}
