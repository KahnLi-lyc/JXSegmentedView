import XCTest
import UIKit
@testable import JXSegmentedView

@MainActor
final class ConcurrencyLifecycleTests: XCTestCase {
    func testAnimatorFinishesOnceAndStopIsReentrant() {
        let animator = JXSegmentedAnimator()
        animator.duration = 1
        var progress: [CGFloat] = []
        var completions = 0
        animator.progressClosure = { value in
            progress.append(value)
            if value == 1 { animator.stop() }
        }
        animator.completedClosure = { completions += 1 }
        animator.start()
        animator.advance(timestamp: 10)
        animator.advance(timestamp: 10.5)
        animator.advance(timestamp: 11)
        animator.stop()
        animator.advance(timestamp: 12)
        XCTAssertEqual(progress, [0, 0.5, 1])
        XCTAssertEqual(completions, 1)
    }

    func testRunningAnimatorAndCellReleaseWithoutWaitingForDuration() {
        weak var weakAnimator: JXSegmentedAnimator?
        weak var weakCell: JXSegmentedTitleCell?
        let model = JXSegmentedTitleItemModel()
        autoreleasepool {
            let animator = JXSegmentedAnimator()
            weakAnimator = animator
            animator.duration = 100
            animator.start()
            let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
            weakCell = cell
            model.title = "Release"
            model.isSelectedAnimable = true
            model.selectedAnimationDuration = 100
            cell.reloadData(itemModel: model, selectedType: .click)
        }
        XCTAssertNil(weakAnimator)
        XCTAssertNil(weakCell)
        XCTAssertFalse(model.isTransitionAnimating)
    }

    func testReplacingOrReusingCellFinishesOldModelBeforeNewAnimation() {
        let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
        func model(_ title: String) -> JXSegmentedTitleItemModel {
            let model = JXSegmentedTitleItemModel()
            model.title = title
            model.isSelectedAnimable = true
            model.selectedAnimationDuration = 100
            return model
        }
        let first = model("First")
        let second = model("Second")
        cell.reloadData(itemModel: first, selectedType: .click)
        let oldAnimator = cell.animator
        cell.reloadData(itemModel: second, selectedType: .click)
        XCTAssertFalse(first.isTransitionAnimating)
        XCTAssertTrue(second.isTransitionAnimating)
        oldAnimator?.stop()
        XCTAssertTrue(second.isTransitionAnimating)
        cell.prepareForReuse()
        cell.prepareForReuse()
        XCTAssertFalse(second.isTransitionAnimating)
        XCTAssertNil(cell.animator)
    }

    func testOldCompletionCannotClearReentrantReplacementAnimation() {
        let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
        let model = JXSegmentedTitleItemModel()
        model.title = "Same model replacement"
        model.isSelectedAnimable = true
        model.selectedAnimationDuration = 100
        cell.reloadData(itemModel: model, selectedType: .click)
        var replacementProgress = 0
        cell.appendSelectedAnimationClosure { value in
            guard value == 1 else { return }
            cell.reloadData(itemModel: model, selectedType: .click)
            cell.appendSelectedAnimationClosure { _ in replacementProgress += 1 }
        }
        let oldAnimator = cell.animator
        oldAnimator?.stop()
        XCTAssertTrue(model.isTransitionAnimating)
        cell.animator?.progressClosure?(0.5)
        XCTAssertEqual(replacementProgress, 1)
        cell.prepareForReuse()
        XCTAssertFalse(model.isTransitionAnimating)
    }

    func testKVOReplacementKeepsOpenHookAndIgnoresOldScrollView() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["One", "Two", "Three"]
        let segmented = ObservedSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        segmented.dataSource = source
        let first = TrackingScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
        let second = TrackingScrollView(frame: first.frame)
        first.contentSize.width = 960
        second.contentSize.width = 960
        segmented.contentScrollView = first
        segmented.reloadData()
        segmented.layoutIfNeeded()
        first.contentOffset.x = 320
        XCTAssertEqual(segmented.selectedIndex, 1)
        segmented.contentScrollView = second
        let notifications = segmented.notifications
        first.contentOffset.x = 640
        XCTAssertEqual(segmented.notifications, notifications)
        second.contentOffset.x = 640
        XCTAssertEqual(segmented.selectedIndex, 2)
        XCTAssertEqual(segmented.lastChangeKind, NSKeyValueChange.setting.rawValue)
        segmented.contentScrollView = nil
        let detachedNotifications = segmented.notifications
        second.contentOffset.x = 320
        XCTAssertEqual(segmented.notifications, detachedNotifications)
    }

    func testReloadInvalidatesDelayedWidthZoomSelection() async throws {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["One", "Two", "Three"]
        source.isItemWidthZoomEnabled = true
        source.selectedAnimationDuration = 0.02
        let segmented = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        segmented.dataSource = source
        segmented.reloadData()
        segmented.layoutIfNeeded()
        segmented.selectItemAt(index: 1)
        segmented.selectItemAt(index: 2)
        source.titles = []
        segmented.reloadData()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(segmented.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(segmented.selectedIndex, 0)
    }

    func testPendingSelectionAndObservationDoNotRetainView() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["One", "Two"]
        source.isItemWidthZoomEnabled = true
        source.selectedAnimationDuration = 100
        let scroll = TrackingScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
        weak var weakSegmented: JXSegmentedView?
        autoreleasepool {
            let segmented = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
            weakSegmented = segmented
            segmented.dataSource = source
            segmented.contentScrollView = scroll
            segmented.reloadData()
            segmented.selectItemAt(index: 1)
        }
        XCTAssertNil(weakSegmented)
        scroll.contentOffset.x = 320
    }
}

private final class TrackingScrollView: UIScrollView {
    override var isTracking: Bool { true }
}

private final class ObservedSegmentedView: JXSegmentedView {
    var notifications = 0
    var lastChangeKind: UInt?
    nonisolated override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let kind = change?[.kindKey] as? UInt
        precondition(Thread.isMainThread)
        MainActor.assumeIsolated {
            notifications += 1
            lastChangeKind = kind
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
