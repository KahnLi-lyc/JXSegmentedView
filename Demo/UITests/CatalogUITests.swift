import XCTest
import UIKit

@MainActor
final class CatalogUITests: XCTestCase {
    private var app: XCUIApplication { XCUIApplication() }

    private func open(_ id: String) {
        continueAfterFailure = false
        app.launch()
        let route = app.cells["route.\(id)"]
        for _ in 0..<8 where !route.isHittable { app.tables["catalog"].swipeUp() }
        XCTAssertTrue(route.waitForExistence(timeout: 5))
        route.tap()
        XCTAssertTrue(app.staticTexts["observation"].waitForExistence(timeout: 5))
        observe("items=4")
    }

    private func observe(_ fragment: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "value CONTAINS %@", fragment)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts["observation"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, fragment, file: file, line: line)
    }

    private func metric(_ key: String, element: XCUIElement? = nil) -> Int {
        let element = element ?? app.staticTexts["observation"]
        let text = element.value as? String ?? element.label
        let prefix = "\(key)="
        guard let token = text.split(whereSeparator: \.isWhitespace).first(where: { $0.hasPrefix(prefix) }),
              let number = Int(token.dropFirst(prefix.count)) else {
            XCTFail("Missing numeric observation: \(key) in \(text)")
            return -1
        }
        return number
    }

    private func observeNested(_ fragment: String, index: Int = 0) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", fragment), object: app.staticTexts["nested.observation.\(index)"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, fragment)
    }

    /// Drag in the outer margin so a nested vertical list cannot consume this gesture.
    private func scrollLab(up: Bool) {
        let outer = app.scrollViews["lab.scroll"]
        let start = outer.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: up ? 0.85 : 0.2))
        let end = outer.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: up ? 0.2 : 0.85))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func tap(_ id: String) {
        let button = app.buttons[id]
        if !button.isHittable {
            for _ in 0..<6 where !button.isHittable { scrollLab(up: true) }
            for _ in 0..<6 where !button.isHittable { scrollLab(up: false) }
        }
        XCTAssertTrue(button.isHittable, id)
        button.tap()
    }

    private func back() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.tables["catalog"].waitForExistence(timeout: 5))
    }

    /// Every preset exercises the library; observations come from selectedIndex and delegate callbacks.
    private func exercise(_ id: String, presets: Int) {
        open(id)
        for preset in 0..<presets {
            XCTAssertTrue(app.staticTexts["preset.name"].label.hasPrefix("\(preset + 1)/\(presets)"))
            let initial = id == "containers" && preset == 3 ? 2 : 0
            observe("selected=\(initial)")
            tap("selection.next")
            observe("selected=\((initial + 1) % 4)")
            observe("selectedCallbacks=\(preset + 1)")
            if preset + 1 < presets { tap("preset.next") }
        }
        back()
    }

    func testTitlesRoute() { exercise("titles", presets: 3) }
    func testAttributedRoute() { exercise("attributed", presets: 3) }
    func testGradientRoute() { exercise("gradient", presets: 2) }
    func testImagesRoute() { exercise("images", presets: 7) }
    func testTitleOrImageRoute() { exercise("title-or-image", presets: 2) }
    func testBadgesRoute() { exercise("badges", presets: 3) }
    func testIndicatorsRoute() { exercise("indicators", presets: 16) }
    func testLayoutRoute() { exercise("layout", presets: 8) }
    func testTypographyRoute() { exercise("typography", presets: 8) }
    func testContainersRoute() { exercise("containers", presets: 5) }
    func testNestedRoute() { exercise("nested", presets: 2) }
    func testNavigationRoute() { exercise("navigation", presets: 2) }
    func testCustomRoute() { exercise("custom", presets: 2) }
    func testDynamicRoute() { exercise("dynamic", presets: 2) }

    func testClickAndPagingCallbacksAndLazyLists() {
        open("containers")
        observe("loaded=[0]")
        let tab = app.descendants(matching: .any)["tab.1"].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
        observe("selected=1")
        observe("clicks=1")
        observe("loaded=[0,1]")
        app.scrollViews["paging"].swipeLeft()
        observe("selected=2")
        observe("swipes=1")
        observe("loaded=[0,1,2]")
        XCTAssertFalse((app.staticTexts["observation"].value as? String ?? "").contains("lifecycle=0"))
        back()
    }

    func testEmptyRestoreInsertDeleteReorderAndReload() {
        open("dynamic")
        tap("data.empty")
        observe("items=0")
        observe("title=empty")
        tap("data.empty")
        observe("items=4")
        tap("data.insert")
        observe("items=5")
        tap("data.delete")
        observe("items=4")
        observe("title=Following")
        tap("data.reorder")
        observe("title=New 5")
        tap("data.item")
        observe("title=New 5 ★")
        tap("data.reload")
        observe("items=4")
        observe("title=New 5 ★")
        observe("reloads=7")
        back()
    }

    func testScrollReplacementAndRapidSelection() {
        open("dynamic")
        tap("selection.next")
        observe("selected=1")
        observe("offsetPage=1.00 visibleTitle=Following selectedModels=1 settled=true")
        tap("data.replace")
        observe("replacements=1")
        let selectedBeforeProbe = metric("selectedCallbacks")
        let swipesBeforeProbe = metric("swipes")
        let progressBeforeProbe = metric("progress")
        tap("data.old-scroll")
        observe("oldTracking=true oldOffsetPage=2.00")
        observe("selected=1")
        observe("offsetPage=1.00 visibleTitle=Following selectedModels=1 settled=true")
        XCTAssertEqual(metric("selectedCallbacks"), selectedBeforeProbe)
        XCTAssertEqual(metric("swipes"), swipesBeforeProbe)
        XCTAssertEqual(metric("progress"), progressBeforeProbe)
        let callbacksBeforeRapid = metric("selectedCallbacks")
        tap("data.rapid")
        observe("selectedCallbacks=\(callbacksBeforeRapid + 5)")
        observe("selected=2")
        observe("offsetPage=2.00 visibleTitle=Saved selectedModels=1 settled=true")
        let paging = app.scrollViews["paging"]
        for _ in 0..<6 where !paging.isHittable { scrollLab(up: false) }
        paging.swipeLeft()
        observe("selected=3")
        observe("offsetPage=3.00 visibleTitle=For you selectedModels=1 settled=true")
        observe("swipes=1")
        back()
    }

    func testNoIndicatorAndMultipleIndicators() {
        open("indicators")
        for _ in 0..<11 { tap("preset.next") }
        observe("indicators=0 frames=[]")
        tap("selection.next")
        observe("selected=1")
        tap("preset.next")
        observe("indicators=2")
        tap("selection.next")
        observe("selected=1")
        XCTAssertFalse((app.staticTexts["observation"].value as? String ?? "").contains("frames=[0x0"))
        back()
    }

    func testNestedInnerPagingAndOuterSelectionAreIndependent() {
        open("nested")
        let inner = app.scrollViews["nested.paging.0"]
        XCTAssertTrue(inner.waitForExistence(timeout: 5))
        observeNested("contained=true")
        let state = app.staticTexts["nested.observation.0"]
        let appeared = metric("innerDidAppear", element: state)
        let disappeared = metric("innerDidDisappear", element: state)
        inner.swipeLeft()
        observeNested("Inner selected=1 callbacks=1 contained=true")
        observeNested("innerDidAppear=\(appeared + 1)")
        observeNested("innerDidDisappear=\(disappeared + 1)")
        observeNested("lastInner=didAppear:1")
        observe("selected=0")
        tap("selection.next")
        observe("selected=1")
        observe("offsetPage=1.00 visibleTitle=Following selectedModels=1 settled=true")
        XCTAssertTrue(app.scrollViews["nested.paging.1"].waitForExistence(timeout: 5))
        observeNested("contained=true", index: 1)
        // The outer controller suppresses automatic forwarding; leaving a page must still
        // disappear its currently selected inner list exactly once.
        observe("nested0DidAppear=\(appeared + 1) nested0DidDisappear=\(disappeared + 2)")
        tap("selection.previous")
        observe("selected=0")
        observe("offsetPage=0.00 visibleTitle=Discover selectedModels=1 settled=true")
        observe("nested0DidAppear=\(appeared + 2) nested0DidDisappear=\(disappeared + 2)")
        observeNested("Inner selected=1 callbacks=1 contained=true")
        observeNested("lastInner=didAppear:1")
        back()
    }

    func testNestedPresetCleanupFinishesAppearanceAndRemovesHost() {
        open("nested")
        observeNested("contained=true")
        tap("preset.next")
        observe("retiredNestedDisappearDelta=1 retiredHostAttached=false")
        observeNested("contained=true")
        back()
    }

    func testClickGateUsesDelegate() {
        open("dynamic")
        tap("data.gate")
        observe("gate=1")
        let tab = app.descendants(matching: .any)["tab.1"].firstMatch
        for _ in 0..<6 where !tab.isHittable { scrollLab(up: false) }
        tab.tap()
        observe("selected=0")
        observe("clicks=0")
        tap("data.gate")
        for _ in 0..<6 where !tab.isHittable { scrollLab(up: false) }
        tab.tap()
        observe("selected=1")
        observe("clicks=1")
        back()
    }

    func testEnvironmentControlsRebuildWithRealLibraryRTLAndMotionSettings() {
        open("titles")
        tap("environment")
        app.buttons["Appearance"].tap()
        app.buttons["Dark"].tap()
        observe("appearance=dark")
        tap("environment")
        app.buttons["Right to left"].tap()
        observe("rtl=true")
        tap("environment")
        app.buttons["Reduce motion (demo)"].tap()
        observe("reduceMotion=true")
        observe("contentAnimation=false selectedAnimation=false widthAnimation=false indicatorDurations=[0.00]")
        tap("selection.next")
        observe("selected=1")
        back()
    }

    func testReducedMotionCoversMaskCompositeAndNestedControls() {
        open("typography")
        for _ in 0..<3 { tap("preset.next") }
        tap("environment")
        app.buttons["Reduce motion (demo)"].tap()
        observe("contentAnimation=false selectedAnimation=false widthAnimation=false indicatorDurations=[0.00]")
        tap("selection.next")
        observe("selected=1")
        back()
        let indicatorsRoute = app.cells["route.indicators"]
        for _ in 0..<8 where !indicatorsRoute.isHittable { app.tables["catalog"].swipeUp() }
        for _ in 0..<8 where !indicatorsRoute.isHittable { app.tables["catalog"].swipeDown() }
        indicatorsRoute.tap()
        for _ in 0..<12 { tap("preset.next") }
        observe("indicatorDurations=[0.00,0.00]")
        observe("contentAnimation=false selectedAnimation=false widthAnimation=false")
        back()
        let nestedRoute = app.cells["route.nested"]
        for _ in 0..<8 where !nestedRoute.isHittable { app.tables["catalog"].swipeUp() }
        nestedRoute.tap()
        observeNested("contained=true")
        observeNested("contentAnimation=false selectedAnimation=false widthAnimation=false indicatorDurations=[0.00]")
        back()
    }

    func testIPadResizeAndCollectionContainer() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Focused iPad case")
        open("containers")
        tap("preset.next")
        tap("selection.next")
        observe("selected=1")
        XCUIDevice.shared.orientation = .landscapeLeft
        app.scrollViews["paging"].swipeLeft()
        observe("selected=2")
        XCUIDevice.shared.orientation = .portrait
        observe("selected=2")
        back()
    }
}
