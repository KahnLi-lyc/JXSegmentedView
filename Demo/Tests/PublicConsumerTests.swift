import XCTest
import UIKit
import JXSegmentedView

/// These tests deliberately import the package as an external consumer.
@MainActor
final class PublicConsumerTests: XCTestCase {
    func testSelectedFontParticipatesInPublicWidthMeasurement() {
        let source = JXSegmentedTitleDataSource()
        source.titleNormalFont = .systemFont(ofSize: 12)
        source.titleSelectedFont = .boldSystemFont(ofSize: 30)
        let actual = source.widthForTitle("Following", 0)
        let expected = ceil(("Following" as NSString).size(withAttributes: [.font: source.titleSelectedFont!]).width)
        XCTAssertGreaterThanOrEqual(actual, expected)
    }

    func testEmptyRestoreAndSelectionThroughPublicAPI() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["One", "Two", "Three"]
        let view = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: 390, height: 60))
        let observer = SelectionObserver()
        view.dataSource = source
        view.delegate = observer
        view.reloadData()
        view.layoutIfNeeded()
        view.selectItemAt(index: 2)
        XCTAssertEqual(view.selectedIndex, 2)
        XCTAssertEqual(observer.indices, [2])
        source.titles = []
        view.reloadData()
        XCTAssertEqual(view.collectionView.numberOfItems(inSection: 0), 0)
        source.titles = ["Restored", "Again"]
        view.reloadData()
        view.layoutIfNeeded()
        view.selectItemAt(index: 1)
        XCTAssertEqual(view.selectedIndex, 1)
        XCTAssertEqual(observer.indices, [2, 1])
    }

    func testReplacingScrollViewDropsOldObservation() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["One", "Two", "Three"]
        let view = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: 390, height: 60))
        view.dataSource = source
        let observer = SelectionObserver()
        view.delegate = observer
        view.reloadData()
        view.layoutIfNeeded()
        let old = TrackingScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        old.contentSize = CGSize(width: 1170, height: 300)
        let replacement = TrackingScrollView(frame: old.frame)
        replacement.contentSize = old.contentSize
        view.contentScrollView = old
        old.contentOffset.x = 390
        XCTAssertEqual(view.selectedIndex, 1)
        XCTAssertEqual(observer.indices, [1])
        view.contentScrollView = replacement
        old.contentOffset.x = 780
        XCTAssertEqual(view.selectedIndex, 1)
        XCTAssertEqual(observer.indices, [1])
        replacement.contentOffset.x = 780
        XCTAssertEqual(view.selectedIndex, 2)
        XCTAssertEqual(observer.indices, [1, 2])
    }

    func testLazyThresholdLoadsOnlyAfterCrossingAndCompletesLifecycleInOrder() {
        let source = ThresholdSource()
        let container = JXSegmentedListContainerView(dataSource: source, type: .scrollView)
        container.frame = CGRect(x: 0, y: 0, width: 320, height: 200)
        container.initListPercent = 0.8
        container.layoutIfNeeded()
        container.reloadData()
        XCTAssertEqual(container.validListDict.keys.sorted(), [0])
        XCTAssertEqual(source.events, ["willAppear:0", "didAppear:0"])
        let scroll = container.scrollView!
        XCTAssertTrue(scroll.isTracking)
        // Deliver the public scroll delegate callback exactly once at each deterministic offset.
        scroll.delegate = nil
        func move(to fraction: CGFloat) {
            scroll.contentOffset.x = fraction * scroll.bounds.width
            container.scrollViewDidScroll(scroll)
        }
        move(to: 0.79)
        XCTAssertEqual(container.validListDict.keys.sorted(), [0])
        XCTAssertEqual(source.events, ["willAppear:0", "didAppear:0", "willDisappear:0"])
        move(to: 0.81)
        XCTAssertEqual(container.validListDict.keys.sorted(), [0, 1])
        XCTAssertEqual(source.events, ["willAppear:0", "didAppear:0", "willDisappear:0"])
        move(to: 0.82)
        XCTAssertEqual(source.events, ["willAppear:0", "didAppear:0", "willDisappear:0", "willAppear:1"])
        move(to: 1)
        XCTAssertEqual(container.validListDict.keys.sorted(), [0, 1])
        XCTAssertEqual(source.events, ["willAppear:0", "didAppear:0", "willDisappear:0", "willAppear:1", "didDisappear:0", "didAppear:1"])
    }

    func testIndicatorPublicGeometryHandlesContentWidthAndInsets() {
        let indicator = JXSegmentedIndicatorLineView()
        indicator.isIndicatorWidthSameAsItemContent = true
        indicator.indicatorWidthIncrement = 12
        indicator.indicatorHeight = 4
        indicator.verticalOffset = 3
        indicator.refreshIndicatorState(model: .init(currentSelectedIndex: 0, currentSelectedItemFrame: CGRect(x: 20, y: 0, width: 120, height: 60), selectedType: .unknown, currentItemContentWidth: 64, collectionViewContentSize: nil))
        XCTAssertEqual(indicator.frame.width, 76)
        XCTAssertEqual(indicator.frame.midX, 80)
        XCTAssertEqual(indicator.frame.minY, 53)
    }
}

@MainActor
private final class SelectionObserver: JXSegmentedViewDelegate {
    var indices: [Int] = []
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) { indices.append(index) }
}

@MainActor
private final class TrackingScrollView: UIScrollView {
    override var isTracking: Bool { true }
}

@MainActor
private final class ThresholdSource: NSObject, JXSegmentedListContainerViewDataSource {
    var events: [String] = []
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int { 3 }
    func scrollViewClass(in listContainerView: JXSegmentedListContainerView) -> AnyClass { TrackingScrollView.self }
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> any JXSegmentedListContainerViewListDelegate {
        LifecycleList(index: index) { [weak self] event in self?.events.append(event) }
    }
}

@MainActor
private final class LifecycleList: UIView, JXSegmentedListContainerViewListDelegate {
    private let index: Int
    private let record: @MainActor (String) -> Void
    init(index: Int, record: @escaping @MainActor (String) -> Void) { self.index = index; self.record = record; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func listView() -> UIView { self }
    func listWillAppear() { record("willAppear:\(index)") }
    func listDidAppear() { record("didAppear:\(index)") }
    func listWillDisappear() { record("willDisappear:\(index)") }
    func listDidDisappear() { record("didDisappear:\(index)") }
}
