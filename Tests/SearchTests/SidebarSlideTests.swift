import XCTest
@testable import Search

/// Settings › Tabs › Sidebar slide speed (Prefs.swift, Fold.swift): the
/// pace everyone gets is the one the column has always had, a speed asked
/// for is remembered between launches, one the slider doesn't offer is
/// brought back into range, and faster means a shorter spring.
@MainActor
final class SidebarSlideTests: XCTestCase {
    private let key = "sidebar.slideSpeed"

    /// This run's settings suite with the speed taken out of it, so each
    /// test starts as a browser nobody has configured.
    private func unconfigured() {
        Store.settings.removeObject(forKey: key)
    }

    func testThePaceEveryoneGets() {
        unconfigured()
        let prefs = Preferences()
        XCTAssertEqual(prefs.sideSlideSpeed, 1.0)
        XCTAssertNil(Store.settings.object(forKey: key), "an unset preference isn't written out")
        Store.settings.removeObject(forKey: key)
    }

    func testASlideIsRememberedBetweenLaunches() {
        unconfigured()
        Preferences().sideSlideSpeed = 1.4
        XCTAssertEqual(Store.settings.object(forKey: key) as? Double, 1.4, "stored as the number it is")
        XCTAssertEqual(Preferences().sideSlideSpeed, 1.4, "a later launch reads it back")
        Store.settings.removeObject(forKey: key)
        XCTAssertEqual(Preferences().sideSlideSpeed, 1.0, "and goes home when it's gone")
    }

    func testASpeedTheSliderDoesntOfferIsBroughtBackIntoRange() {
        unconfigured()
        Store.settings.set(9.0, forKey: key)
        XCTAssertEqual(Preferences().sideSlideSpeed, 2.0, "too fast for the slider is the slider's fastest")
        Store.settings.set(0.1, forKey: key)
        XCTAssertEqual(Preferences().sideSlideSpeed, 0.5, "too slow is its slowest")
        Store.settings.set("sideways", forKey: key)
        XCTAssertEqual(Preferences().sideSlideSpeed, 1.0, "and something that isn't a speed at all is the pace everyone gets")
        Store.settings.removeObject(forKey: key)
    }

    func testFasterMeansAShorterSpring() {
        let usual = Motion.response(at: 1.0)
        XCTAssertEqual(usual, Motion.glideResponse, accuracy: 1e-9, "speed 1 is the glide as it always was")
        XCTAssertEqual(Motion.response(at: 2.0), usual / 2, accuracy: 1e-9, "twice the speed, half the time")
        XCTAssertEqual(Motion.response(at: 0.5), usual * 2, accuracy: 1e-9, "half the speed, twice the time")
        XCTAssertEqual(Motion.response(at: 0.1), Motion.response(at: 0.25), accuracy: 1e-9, "a speed nobody offers can't make the spring snap")
    }

    func testTheSlideIsARealAnimationAtAnySpeed() {
        for speed in [0.5, 1.0, 2.0] {
            XCTAssertNotNil(Motion.glide(speed: speed), "speed \(speed) still springs")
        }
    }
}
