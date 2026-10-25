import Foundation

@main
struct BehaviorTests {
    static func main() {
        assert(WindowBehavior.opacity(isActive: true, dimWhenInactive: true, inactiveOpacity: 0.35) == 1)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: false, inactiveOpacity: 0.35) == 1)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: 0.65) == 0.65)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: -5) == 0.25)
        assert(WindowBehavior.opacity(isActive: false, dimWhenInactive: true, inactiveOpacity: 5) == 1)
        print("5 window behavior checks passed.")
    }
}
