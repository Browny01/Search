import XCTest
@testable import Search

/// Settings › Tabs › Wait before the sidebar shows (Prefs.swift, Fold.swift):
/// the wait everyone gets is the one the column has always had, a wait
/// asked for is remembered between launches, one the slider doesn't offer
/// is brought back into range, and 0 means the moment the edge is touched.
@MainActor
final class SidebarDwellTests: XCTestCase {
    private let key = "sidebar.dwell"

    /// This run's settings suite with the wait taken out of it, so each
    /// test starts as a browser nobody has configured.
    private func unconfigured() {
        Store.settings.removeObject(forKey: key)
    }

    func testTheWaitEveryoneGets() {
        unconfigured()
        let prefs = Preferences()
        XCTAssertEqual(prefs.sideDwell, 0.15, accuracy: 1e-9)
        XCTAssertNil(Store.settings.object(forKey: key), "an unset preference isn't written out")
        Store.settings.removeObject(forKey: key)
    }

    func testAWaitIsRememberedBetweenLaunches() {
        unconfigured()
        Preferences().sideDwell = 0.05
        XCTAssertEqual(Store.settings.object(forKey: key) as? Double, 0.05, "stored as the number it is")
        XCTAssertEqual(Preferences().sideDwell, 0.05, "a later launch reads it back")
        Store.settings.removeObject(forKey: key)
        XCTAssertEqual(Preferences().sideDwell, 0.15, accuracy: 1e-9, "and goes home when it's gone")
    }

    func testAWaitOutsideTheSliderIsBroughtBackIntoRange() {
        unconfigured()
        Store.settings.set(9.0, forKey: key)
        XCTAssertEqual(Preferences().sideDwell, 0.45, accuracy: 1e-9, "longer than the slider offers is its longest")
        Store.settings.set(-1.0, forKey: key)
        XCTAssertEqual(Preferences().sideDwell, 0.0, "negative is the moment the edge is touched")
        Store.settings.set("later", forKey: key)
        XCTAssertEqual(Preferences().sideDwell, 0.15, accuracy: 1e-9, "and something that isn't a wait is the wait everyone gets")
        Store.settings.removeObject(forKey: key)
    }
}
