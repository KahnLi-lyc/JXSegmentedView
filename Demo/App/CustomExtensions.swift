import UIKit
import JXSegmentedView

/// Public extension hooks: the custom item carries a subtitle, and its cell draws a capsule.
@MainActor
final class CapsuleItemModel: JXSegmentedTitleItemModel {
    var subtitle = ""
}

@MainActor
final class CapsuleDataSource: JXSegmentedTitleDataSource {
    override func preferredItemModelInstance() -> JXSegmentedBaseItemModel { CapsuleItemModel() }
    override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
        (itemModel as? CapsuleItemModel)?.subtitle = "COLLECTION 0\(index + 1)"
    }
    override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat { 142 }
    override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(CapsuleCell.self, forCellWithReuseIdentifier: "capsule")
    }
    override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        segmentedView.dequeueReusableCell(withReuseIdentifier: "capsule", at: index)
    }
}

@MainActor
final class CapsuleCell: JXSegmentedBaseCell {
    private let heading = UILabel()
    private let caption = UILabel()
    override func commonInit() {
        super.commonInit()
        heading.font = .systemFont(ofSize: 16, weight: .semibold)
        caption.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        caption.textColor = .secondaryLabel
        contentView.addSubview(heading)
        contentView.addSubview(caption)
        contentView.layer.cornerRadius = 15
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        heading.frame = CGRect(x: 12, y: 12, width: bounds.width - 24, height: 24)
        caption.frame = CGRect(x: 12, y: 38, width: bounds.width - 24, height: 16)
    }
    override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType)
        guard let model = itemModel as? CapsuleItemModel else { return }
        heading.text = model.title
        heading.textColor = model.titleCurrentColor
        caption.text = model.subtitle
        contentView.backgroundColor = model.isSelected ? UIColor.systemIndigo.withAlphaComponent(0.12) : .secondarySystemBackground
    }
}

/// Custom indicator implements all three hooks, including interactive interpolation.
@MainActor
final class BracketIndicator: JXSegmentedIndicatorBaseView {
    private let shape = CAShapeLayer()
    override func commonInit() {
        super.commonInit()
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.systemOrange.cgColor
        shape.lineWidth = 3
        layer.addSublayer(shape)
        isIndicatorConvertToItemFrameEnabled = false
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 1, y: 9)); path.addLine(to: CGPoint(x: 1, y: 1)); path.addLine(to: CGPoint(x: bounds.width - 1, y: 1)); path.addLine(to: CGPoint(x: bounds.width - 1, y: 9))
        shape.path = path.cgPath
    }
    override func refreshIndicatorState(model: JXSegmentedIndicatorSelectedParams) { place(model.currentSelectedItemFrame) }
    override func selectItem(model: JXSegmentedIndicatorSelectedParams) { place(model.currentSelectedItemFrame) }
    override func contentScrollViewDidScroll(model: JXSegmentedIndicatorTransitionParams) {
        let p = model.percent
        place(CGRect(x: model.leftItemFrame.minX + (model.rightItemFrame.minX - model.leftItemFrame.minX) * p, y: 0, width: model.leftItemFrame.width + (model.rightItemFrame.width - model.leftItemFrame.width) * p, height: model.leftItemFrame.height))
    }
    private func place(_ item: CGRect) {
        frame = CGRect(x: item.minX + 4, y: 3, width: max(0, item.width - 8), height: 10)
        setNeedsLayout()
    }
}
