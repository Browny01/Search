import XCTest
@testable import Search

/// Settings › Tabs › Sidebar tab density (Prefs.swift): compact is what an
/// unconfigured browser gets and what the column has always measured,
/// roomy measures roomier, and storage that isn't one of the two falls
/// back to compact rather than drawing something odd.
@MainActor
final class SidebarDensityTests: XCTestCase {
    private let key = "sidebar.density"

    /// This run's settings suite with the density taken out of it, so each
    /// test starts as a browser nobody has configured.
    private func unconfigured() {
        Store.settings.removeObject(forKey: key)
    }

    func testCompactIsTheDefault() {
        unconfigured()
        let prefs = Preferences()
        XCTAssertEqual(prefs.sideDensity, .compact)
        XCTAssertNil(Store.settings.string(forKey: key), "an unset preference isn't written out")
        Store.settings.removeObject(forKey: key)
    }

    func testRoomyIsRememberedBetweenLaunches() {
        unconfigured()
        Preferences().sideDensity = .roomy
        XCTAssertEqual(Store.settings.string(forKey: key), "roomy", "stored as its raw value")
        XCTAssertEqual(Preferences().sideDensity, .roomy, "a later launch reads it back")
        Store.settings.removeObject(forKey: key)
        XCTAssertEqual(Preferences().sideDensity, .compact, "and goes home when it's gone")
    }

    func testAValueThisBuildDoesntKnowFallsBackToCompact() {
        unconfigured()
        Store.settings.set("enormous", forKey: key)
        XCTAssertNil(SidebarDensity(rawValue: "enormous"))
        XCTAssertEqual(Preferences().sideDensity, .compact)
        Store.settings.removeObject(forKey: key)
    }

    func testCompactMeasuresWhatTheColumnAlwaysMeasured() {
        let m = SidebarDensity.compact.metrics
        XCTAssertEqual(m.rowHeight, 28)
        XCTAssertEqual(m.gap, 2)
        XCTAssertEqual(m.titleSize, 12.5)
        XCTAssertEqual(m.iconSize, 15)
        XCTAssertEqual(m.spacing, 8)
    }

    func testRoomyGivesEachRowClearlyMoreRoomWithoutOvershooting() {
        let compact = SidebarDensity.compact.metrics
        let roomy = SidebarDensity.roomy.metrics
        let share = roomy.rowHeight / compact.rowHeight
        XCTAssertGreaterThanOrEqual(share, 1.25, "noticeably taller than compact")
        XCTAssertLessThanOrEqual(share, 1.40, "still a browser's sidebar, not a card list")
        XCTAssertGreaterThan(roomy.gap, compact.gap, "more separation between neighbours")
        XCTAssertGreaterThan(roomy.titleSize, compact.titleSize, "a subtly larger title")
        XCTAssertGreaterThan(roomy.iconSize, compact.iconSize, "the mark keeps its proportion")
        XCTAssertGreaterThan(roomy.spacing, compact.spacing, "air between the mark and the title")
    }

    func testEveryDensityDrawsFromItsOwnMetrics() {
        for density in SidebarDensity.allCases {
            let m = density.metrics
            XCTAssertGreaterThan(m.rowHeight, 0)
            XCTAssertGreaterThan(m.gap, 0)
            XCTAssertGreaterThan(m.titleSize, 0)
            XCTAssertGreaterThan(m.iconSize, 0)
            XCTAssertGreaterThan(m.spacing, 0)
        }
    }
}
