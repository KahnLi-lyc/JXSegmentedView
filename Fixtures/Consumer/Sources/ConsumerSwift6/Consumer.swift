import UIKit
import JXSegmentedView

// Public imports only: these witnesses must work across the module boundary.
@MainActor
final class ObjectList: NSObject, JXSegmentedListContainerViewListDelegate {
    private let contentView = UIView()
    func listView() -> UIView { contentView }
}

@MainActor
final class ControllerList: UIViewController, JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView { view }
    func listWillAppear() { view.setNeedsLayout() }
}

@MainActor
final class SegmentedDelegate: NSObject, JXSegmentedViewDelegate, JXSegmentedListContainerViewDataSource {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        segmentedView.setNeedsLayout()
    }
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int { 2 }
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        index == 0 ? ObjectList() : ControllerList()
    }
}

@MainActor
final class ObjectDataSource: NSObject, JXSegmentedViewDataSource {
    var isItemWidthZoomEnabled = false
    var selectedAnimationDuration: TimeInterval = 0.2
    var itemSpacing: CGFloat = 12
    var isItemSpacingAverageEnabled = true
    private var models: [JXSegmentedBaseItemModel] = []
    func reloadData(selectedIndex: Int) { models = [CustomItemModel()] }
    func itemDataSource(in segmentedView: JXSegmentedView) -> [JXSegmentedBaseItemModel] { models }
    func segmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat { 80 }
    func segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int) -> CGFloat { 60 }
    func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "ConsumerCell")
    }
    func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        segmentedView.collectionView.dequeueReusableCell(withReuseIdentifier: "ConsumerCell", for: IndexPath(item: index, section: 0)) as! CustomCell
    }
    func refreshItemModel(_ segmentedView: JXSegmentedView, _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        itemModel.isSelected = index == selectedIndex
    }
    func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel,
        willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        currentSelectedItemModel.isSelected = false
        willSelectedItemModel.isSelected = true
    }
    func refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: JXSegmentedBaseItemModel,
        rightItemModel: JXSegmentedBaseItemModel, percent: CGFloat) { leftItemModel.itemWidth = percent }
}

@MainActor
final class CustomSegmentedView: JXSegmentedView {
    override func layoutSubviews() { super.layoutSubviews() }
}

@MainActor
final class CustomDataSource: JXSegmentedTitleDataSource {
    override func preferredItemModelInstance() -> JXSegmentedBaseItemModel { CustomItemModel() }
}

@MainActor
final class CustomItemModel: JXSegmentedTitleItemModel {}

@MainActor
final class CustomCell: JXSegmentedTitleCell {
    override func commonInit() { super.commonInit() }
    override func preferredTitleColorAnimateClosure(itemModel: JXSegmentedTitleItemModel) -> JXSegmentedCellSelectedAnimationClosure {
        super.preferredTitleColorAnimateClosure(itemModel: itemModel)
    }
}

@MainActor
final class CustomIndicator: JXSegmentedIndicatorLineView {
    override func commonInit() { super.commonInit() }
}

@MainActor
final class CustomContainer: JXSegmentedListContainerView {
    override func commonInit() { super.commonInit() }
}

@MainActor
public func makeConsumerView() -> UIView {
    let delegate = SegmentedDelegate()
    let segmented = CustomSegmentedView()
    let dataSource = CustomDataSource()
    dataSource.titles = ["One", "Two"]
    dataSource.widthForTitleClosure = { title in CGFloat(title.count) * 12 }
    let imageSource = JXSegmentedTitleImageDataSource()
    imageSource.loadImageClosure = { imageView, _ in imageView.image = UIImage() }
    let animator = JXSegmentedAnimator()
    animator.progressClosure = { _ in segmented.setNeedsLayout() }
    animator.stop()
    segmented.dataSource = dataSource
    segmented.delegate = delegate
    segmented.indicators = [CustomIndicator()]
    segmented.listContainer = CustomContainer(dataSource: delegate)
    segmented.reloadData()
    return segmented
}
