import Foundation

@main
struct BehaviorTests {
    static func main() {
        assert(WindowBehavior.opacity(isActive: true, dimWhenInactive: true, inactiveOpacity: 0.35) == 1)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: false, inactiveOpacity: 0.35) == 1)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: 0.65) == 0.65)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: -5) == 0.05)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: 5) == 0.95)
        assert(WindowBehavior.inactiveOpacityPercentages == [5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95])
        for percent in WindowBehavior.inactiveOpacityPercentages {
            let value = Double(percent) / 100
            assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: value) == value)
        }
        assert(WindowBehavior.normalizedInactiveOpacity(0.65) == 0.60)
        assert(WindowBehavior.normalizedInactiveOpacity(0.35) == 0.30)
        assert(WindowBehavior.normalizedInactiveOpacity(0.80) == 0.80)
        assert(WindowBehavior.normalizedInactiveOpacity(-1) == 0.05)
        assert(WindowBehavior.normalizedInactiveOpacity(10) == 0.95)
        assert(WindowBehavior.normalizedInactiveOpacity(.nan) == 0.60)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: .nan) == 0.60)
        print("24 window behavior checks passed.")
    }
}
